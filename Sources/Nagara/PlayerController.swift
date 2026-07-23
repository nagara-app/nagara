import AVFoundation
import Foundation

final class PlayerController: NSObject {
    enum State: Equatable { case stopped, connecting, playing, failed }

    private(set) var state: State = .stopped {
        didSet { if state != oldValue { onStateChange?(state) } }
    }
    private(set) var currentChannel: Channel?
    /// ICYメタデータのStreamTitleを受け取ったまま保持する生文字列（並べ替えなし）。
    /// 慣例上は "Artist - Title" 形式で流れてくることが多いが、保証はない。
    private(set) var currentTrack: String? {
        didSet { if currentTrack != oldValue { onTrackChange?(currentTrack) } }
    }
    var onStateChange: ((State) -> Void)?
    var onTrackChange: ((String?) -> Void)?

    var volume: Float = 0.125 {
        didSet { player?.volume = volume }
    }

    private var player: AVPlayer?
    private var statusObservation: NSKeyValueObservation?
    private var reconnectAttempt = 0
    private var pendingReconnect: DispatchWorkItem?

    /// 再生せずに選択チャンネルだけ復元する（起動時自動再生をしない要件のため）
    func prepare(_ channel: Channel) {
        guard state == .stopped else { return }
        currentChannel = channel
    }

    func play(_ channel: Channel) {
        // failed後の手動リトライではバックオフを最初からやり直す。
        // scheduleReconnectのwork item経由の呼び出し時はstateが.connectingなのでリセットされない。
        let shouldResetAttempt = channel.id != currentChannel?.id || state == .failed
        teardown()
        if shouldResetAttempt { reconnectAttempt = 0 }
        currentChannel = channel
        currentTrack = nil
        state = .connecting

        let item = AVPlayerItem(url: channel.url)
        let metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metadataOutput.setDelegate(self, queue: .main)
        item.add(metadataOutput)

        NotificationCenter.default.addObserver(
            self, selector: #selector(itemFailed),
            name: .AVPlayerItemFailedToPlayToEndTime, object: item)
        NotificationCenter.default.addObserver(
            self, selector: #selector(itemStalled),
            name: .AVPlayerItemPlaybackStalled, object: item)

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.reconnectAttempt = 0
                    self.state = .playing
                case .failed:
                    self.scheduleReconnect()
                default:
                    break
                }
            }
        }

        let player = AVPlayer(playerItem: item)
        player.volume = volume
        player.play()
        self.player = player
    }

    func stop() {
        teardown()
        state = .stopped
    }

    func togglePlayPause() {
        switch state {
        case .playing, .connecting:
            stop()
        case .stopped, .failed:
            if let channel = currentChannel { play(channel) }
        }
    }

    @objc private func itemFailed(_ note: Notification) {
        DispatchQueue.main.async { [weak self] in self?.scheduleReconnect() }
    }
    @objc private func itemStalled(_ note: Notification) {
        DispatchQueue.main.async { [weak self] in self?.scheduleReconnect() }
    }

    /// ReconnectPolicyに従い自動再接続。上限超過で failed 表示にして停止。
    private func scheduleReconnect() {
        // KVOの.failedパスと通知(FailedToPlayToEndTime/Stalled)が同一の失敗に対して
        // 二重発火し得るため、pendingReconnectが残っている間は再度スケジュールしない。
        guard pendingReconnect == nil else { return }
        guard let channel = currentChannel, state != .stopped else { return }
        guard let delay = ReconnectPolicy.delay(forAttempt: reconnectAttempt) else {
            teardown()
            state = .failed
            return
        }
        reconnectAttempt += 1
        state = .connecting
        let work = DispatchWorkItem { [weak self] in
            self?.pendingReconnect = nil
            self?.play(channel)
        }
        pendingReconnect = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    /// 状態遷移は行わず、接続まわりのリソースのみを片付ける。
    /// stop()（→.stopped）とgive-up時（→.failed）の共通処理として使う。
    private func teardown() {
        pendingReconnect?.cancel()
        pendingReconnect = nil
        NotificationCenter.default.removeObserver(self)
        statusObservation = nil
        player?.pause()
        player = nil
        currentTrack = nil
    }
}

extension PlayerController: AVPlayerItemMetadataOutputPushDelegate {
    func metadataOutput(
        _ output: AVPlayerItemMetadataOutput,
        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
        from track: AVPlayerItemTrack?
    ) {
        // Icecast系ストリームはICYメタデータ(StreamTitle)で "Artist - Title" を流す
        for group in groups {
            for item in group.items {
                if item.identifier == .icyMetadataStreamTitle,
                   let title = item.stringValue, !title.isEmpty {
                    currentTrack = title
                    return
                }
            }
        }
    }
}
