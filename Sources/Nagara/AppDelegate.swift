import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusItemController?
    private var nowPlaying: NowPlayingBridge?
    private let player = PlayerController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let channels = ChannelStore.load(configURL: ChannelStore.defaultConfigURL)
        statusController = StatusItemController(
            player: player, settings: Settings(), channels: channels)
        nowPlaying = NowPlayingBridge(player: player)
    }
}
