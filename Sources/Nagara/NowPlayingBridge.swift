import Foundation
import MediaPlayer

/// メディアキー(▶❚❚)・AirPods操作・コントロールセンター対応。
/// Spotify等の他アプリと「今の再生中」の座を取り合う点は既知の留意点。
final class NowPlayingBridge {
    private let player: PlayerController

    init(player: PlayerController) {
        self.player = player

        let center = MPRemoteCommandCenter.shared()
        // メディアキーはメインスレッド配送が保証されないためmainへ寄せる
        center.playCommand.addTarget { [weak player] _ in
            DispatchQueue.main.async { player?.togglePlayPause() }
            return .success
        }
        center.pauseCommand.addTarget { [weak player] _ in
            DispatchQueue.main.async { player?.togglePlayPause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak player] _ in
            DispatchQueue.main.async { player?.togglePlayPause() }
            return .success
        }
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
        // 送り込んできて勝手に再生が始まる（再生開始はメニューからのみ行う）。
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
