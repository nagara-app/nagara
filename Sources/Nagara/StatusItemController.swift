import AppKit
import ServiceManagement

final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let player: PlayerController
    private var settings: Settings
    private let channels: [Channel]
    private let menu = NSMenu()
    private let settingsMenu = NSMenu()
    private weak var playButton: NSButton?
    private var connectingTimer: Timer?
    private var connectingFrame = 0

    init(player: PlayerController, settings: Settings, channels: [Channel]) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.player = player
        self.settings = settings
        self.channels = channels
        super.init()

        menu.delegate = self
        menu.autoenablesItems = false  // isEnabled を手動制御するため
        settingsMenu.delegate = self
        settingsMenu.autoenablesItems = false

        // statusItem.menu を常設すると左右クリックとも同じメニューになるため、
        // ボタンのアクションでクリック種別を見て出し分ける（右クリック＝設定）
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateIcon(for: player.state)

        player.onStateChange = { [weak self] state in
            self?.updateIcon(for: state)
            self?.updatePlayButton()
        }
        player.volume = VolumeCurve.gain(fromSlider: settings.sliderValue)

        // 最後に聴いていたチャンネルを「選択状態」として復元（自動再生はしない）
        if let last = settings.lastChannelID,
           let channel = channels.first(where: { $0.id == last }) {
            player.prepare(channel)
        }
    }

    deinit {
        // RunLoopがタイマーを保持し続けるため明示的に破棄する
        connectingTimer?.invalidate()
    }

    private func updateIcon(for state: PlayerController.State) {
        connectingTimer?.invalidate()
        connectingTimer = nil
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)

        // 接続中はドットが順に点灯するローディング表示
        // （variable colorのフレームをタイマーで循環。NSStatusItemはSymbol Effect非対応のため自前アニメ）
        if state == .connecting {
            let frames = [0.0, 0.34, 0.67, 1.0].compactMap {
                NSImage(systemSymbolName: "ellipsis.circle.fill", variableValue: $0,
                        accessibilityDescription: "Nagara (接続中)")?
                    .withSymbolConfiguration(config)
            }
            if frames.count == 4 {
                connectingFrame = 0
                statusItem.button?.image = frames[0]
                let timer = Timer(timeInterval: 0.3, repeats: true) { [weak self] _ in
                    guard let self else { return }
                    connectingFrame = (connectingFrame + 1) % frames.count
                    statusItem.button?.image = frames[connectingFrame]
                }
                timer.tolerance = 0.05  // 省電力（0.3秒周期なら視覚上の劣化なし）
                // メニュー表示中(eventTracking)でも止まらないよう.commonで回す
                RunLoop.main.add(timer, forMode: .common)
                connectingTimer = timer
                return
            }
            // フレーム生成に失敗した場合は従来どおり静止アイコンにフォールバック
        }

        let name = (state == .playing || state == .connecting) ? "play.circle.fill" : "stop.circle.fill"
        let desc = state == .playing ? "Nagara (再生中)" : "Nagara"
        statusItem.button?.image = NSImage(systemSymbolName: name, accessibilityDescription: desc)?
            .withSymbolConfiguration(config)
    }

    @objc private func statusItemClicked() {
        let isRightClick = NSApp.currentEvent?.type == .rightMouseUp
        statusItem.menu = isRightClick ? settingsMenu : menu
        statusItem.button?.performClick(nil)  // menu設定済みなのでメニュー表示になる（アクション再帰しない）
        statusItem.menu = nil  // メニュー閉了後に常設解除（次回のクリック出し分けのため）
    }

    // メニューを開くたびに現在状態で組み直す
    func menuNeedsUpdate(_ menu: NSMenu) {
        if menu === settingsMenu {
            rebuildSettingsMenu()
        } else {
            rebuildMainMenu()
        }
    }

    private func rebuildMainMenu() {
        menu.removeAllItems()

        // 曲名（取れているときだけ）／エラー表示
        if player.state == .failed {
            let item = NSMenuItem(title: "接続できません", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(.separator())
        } else if let track = player.currentTrack {
            let item = NSMenuItem(title: "♪ \(track)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(.separator())
        }

        // チャンネル一覧（選択中にチェックマーク・genreの変わり目に小さな見出し）
        var currentGenre: String? = nil
        for channel in channels {
            if let genre = channel.genre, genre != currentGenre {
                menu.addItem(NSMenuItem.sectionHeader(title: genre))
            }
            currentGenre = channel.genre
            let item = NSMenuItem(title: channel.name, action: #selector(selectChannel(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = channel
            item.state = (channel.id == player.currentChannel?.id) ? .on : .off
            menu.addItem(item)
        }
        menu.addItem(.separator())

        // 音量スライダー＋再生/停止ボタン（スライダー右側・円形背景）
        let sliderItem = NSMenuItem()
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 36))
        let slider = NSSlider(value: settings.sliderValue, minValue: 0, maxValue: 1,
                              target: self, action: #selector(volumeChanged(_:)))
        slider.frame = NSRect(x: 14, y: 8, width: 156, height: 20)
        slider.isContinuous = true
        container.addSubview(slider)

        let button = NSButton(image: NSImage(), target: self, action: #selector(togglePlay))
        button.isBordered = false
        button.frame = NSRect(x: 182, y: 6, width: 24, height: 24)
        button.wantsLayer = true
        button.layer?.cornerRadius = 12
        button.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.1).cgColor
        container.addSubview(button)
        playButton = button
        updatePlayButton()

        sliderItem.view = container
        menu.addItem(sliderItem)
    }

    // 設定メニュー（ステータスアイコンの右クリックで表示）
    private func rebuildSettingsMenu() {
        settingsMenu.removeAllItems()
        let loginItem = NSMenuItem(title: "ログイン時に起動", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        settingsMenu.addItem(loginItem)
        settingsMenu.addItem(.separator())
        settingsMenu.addItem(NSMenuItem(title: "Nagaraを終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    // 再生状態に応じてスライダー横のボタン表示を更新（メニュー表示中の状態変化にも追従）
    private func updatePlayButton() {
        guard let button = playButton else { return }
        let active = (player.state == .playing || player.state == .connecting)
        let name = active ? "stop.fill" : "play.fill"
        let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        button.image = NSImage(systemSymbolName: name, accessibilityDescription: active ? "停止" : "再生")?
            .withSymbolConfiguration(config)
        button.isEnabled = (player.currentChannel != nil || player.state != .stopped)
    }

    @objc private func togglePlay() { player.togglePlayPause() }

    @objc private func selectChannel(_ sender: NSMenuItem) {
        guard let channel = sender.representedObject as? Channel else { return }
        settings.lastChannelID = channel.id
        player.play(channel)
    }

    @objc private func volumeChanged(_ sender: NSSlider) {
        settings.sliderValue = sender.doubleValue
        player.volume = VolumeCurve.gain(fromSlider: sender.doubleValue)
    }

    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("SMAppService error: \(error)")
        }
    }
}
