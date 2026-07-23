import Foundation

enum ChannelStore {
    /// 確定済みプリセット 5 局（規約・URL・曲調検証済み 2026-07-23）
    static let presets: [Channel] = [
        Channel(id: "lautfm-lofi", name: "laut.fm Lofi",
                url: URL(string: "https://lofi.stream.laut.fm/lofi")!),
        Channel(id: "coderadio", name: "freeCodeCamp Code Radio",
                url: URL(string: "https://coderadio-admin-v2.freecodecamp.org/listen/coderadio/radio.mp3")!),
        Channel(id: "fluxfm-chillhop", name: "FluxFM ChillHop",
                url: URL(string: "https://streams.fluxfm.de/Chillhop/mp3-320/streams.fluxfm.de/")!),
        Channel(id: "lautfm-lofi-radio", name: "laut.fm Lofi Radio",
                url: URL(string: "https://lofi-radio.stream.laut.fm/lofi-radio")!),
        Channel(id: "bigfm-lofi-focus", name: "bigFM LoFi Focus",
                url: URL(string: "https://stream.bigfm.de/lofifocus/mp3-128/radiobrowser")!),
    ]

    static var defaultConfigURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/nagara/channels.json")
    }

    static func load(configURL: URL) -> [Channel] {
        guard let data = try? Data(contentsOf: configURL),
              let channels = try? JSONDecoder().decode([Channel].self, from: data),
              !channels.isEmpty
        else { return presets }
        return channels
    }
}
