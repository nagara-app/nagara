import Foundation
import MediaPlayer

/// メディアキー(▶❚❚)・AirPods操作・コントロールセンター対応。
/// リモートコマンドは「停止」専用で、再生開始はメニューUIからのみ行う設計。
/// Spotify等の他アプリと「今の再生中」の座を取り合う点は既知の留意点。
final class NowPlayingBridge {
    private let player: PlayerController

    init(player: PlayerController) {
        self.player = player

        let center = MPRemoteCommandCenter.shared()
        // リモートコマンドは「停止」専用にする（再生開始はメニューからのみ）。
        // isEnabled = false でも mediaremoted はコマンドを配送してくることがあり、
        // AirPods接続時の自動再開playがここを通ると停止中でも勝手に再生が始まるため、
        // ハンドラ側でも再生開始経路を持たないことを保証する。
        // メディアキーはメインスレッド配送が保証されないためmainへ寄せる
        let stopIfActive: (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus = {
            [weak player] _ in
            DispatchQueue.main.async {
                guard let player else { return }
                if player.state == .playing || player.state == .connecting {
                    player.stop()
                }
            }
            return .success
        }
        // playは再生開始要求なので常に無視し「実行不可」を返す
        // （.successを返すとOSが再生成功と見なしAirPodsのルートを掴み続ける恐れがある）
        center.playCommand.addTarget { _ in .noActionableNowPlayingItem }
        center.pauseCommand.addTarget(handler: stopIfActive)
        center.togglePlayPauseCommand.addTarget(handler: stopIfActive)
        // ラジオなので前後スキップは無効化
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false

        let previousStateHandler = player.onStateChange
        player.onStateChange = { [weak self] state in
            previousStateHandler?(state)
            self?.updateNowPlaying(state: state)
        }
        let previousTrackHandler = player.onTrackChange
        player.onTrackChange = { [weak self] track in
            previousTrackHandler?(track)
            self?.updateNowPlaying(state: self?.player.state ?? .stopped)
        }

        // 起動直後は停止状態なので、コマンド無効化まで含めて初期状態を反映しておく
        updateNowPlaying(state: player.state)
    }

    private func updateNowPlaying(state: PlayerController.State) {
        let infoCenter = MPNowPlayingInfoCenter.default()
        let center = MPRemoteCommandCenter.shared()

        // 停止中はNow Playingの座から完全に降りる。
        // .pausedのまま座に残ると、AirPods等の接続時にmacOSが自動再開のplayを
        // 送り込んでくる（防衛第1線。isEnabled=falseでも配送され得るため、
        // ハンドラ側でも再生開始経路を持たない二段構え）。
        guard state == .playing || state == .connecting else {
            infoCenter.nowPlayingInfo = nil
            infoCenter.playbackState = .stopped
            center.playCommand.isEnabled = false
            center.pauseCommand.isEnabled = false
            center.togglePlayPauseCommand.isEnabled = false
            return
        }

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: player.currentTrack ?? player.currentChannel?.name ?? "Nagara",
            MPMediaItemPropertyArtist: player.currentChannel?.name ?? "",
            MPNowPlayingInfoPropertyIsLiveStream: true,
        ]
        info[MPNowPlayingInfoPropertyPlaybackRate] = (state == .playing) ? 1.0 : 0.0
        infoCenter.nowPlayingInfo = info
        infoCenter.playbackState = (state == .playing) ? .playing : .paused
    }
}
