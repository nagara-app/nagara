import Foundation

enum ChannelStore {
    /// 確定済みプリセット 7 局（規約・URL・曲調検証済み 2026-07-23・試聴選別による）
    static let presets: [Channel] = [
        Channel(id: "coderadio", name: "freeCodeCamp Code Radio",
                url: URL(string: "https://coderadio-admin-v2.freecodecamp.org/listen/coderadio/radio.mp3")!,
                genre: "Lo-fi"),
        Channel(id: "fluxfm-chillhop", name: "FluxFM ChillHop",
                url: URL(string: "https://streams.fluxfm.de/Chillhop/mp3-320/streams.fluxfm.de/")!,
                genre: "Lo-fi"),
        Channel(id: "bigfm-lofi-focus", name: "bigFM LoFi Focus",
                url: URL(string: "https://stream.bigfm.de/lofifocus/mp3-128/radiobrowser")!,
                genre: "Lo-fi"),
        Channel(id: "nia-lofi", name: "NIA Radio Lo-Fi",
                url: URL(string: "https://radio.nia.nc/radio/8020/lofi-hq-stream.aac")!,
                genre: "Lo-fi"),
        Channel(id: "nightride-chillsynth", name: "Nightride Chillsynth",
                url: URL(string: "https://stream.nightride.fm/chillsynth.mp3")!,
                genre: "Synthwave"),
        Channel(id: "nightride-datawave", name: "Nightride Datawave",
                url: URL(string: "https://stream.nightride.fm/datawave.mp3")!,
                genre: "Synthwave"),
        Channel(id: "24dubstep-calmflow", name: "24Dubstep CalmFlow",
                url: URL(string: "https://stream.24dubstep.pl/listen/chillstep/mp3_best")!,
                genre: "Chillstep"),
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
