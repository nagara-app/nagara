import Foundation
import Testing
@testable import Nagara

@Suite struct ChannelStoreTests {
    private func tempFile(_ contents: String?) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("channels.json")
        if let contents {
            try contents.write(to: url, atomically: true, encoding: .utf8)
        }
        return url
    }

    @Test func ファイルが無ければプリセットを返す() throws {
        let channels = ChannelStore.load(configURL: try tempFile(nil))
        #expect(channels == ChannelStore.presets)
        #expect(!channels.isEmpty)
    }
    @Test func 正しいJSONがあればそれを返す() throws {
        let json = #"[{"id":"test","name":"Test FM","url":"https://example.com/stream"}]"#
        let channels = ChannelStore.load(configURL: try tempFile(json))
        #expect(channels.count == 1)
        #expect(channels[0].id == "test")
        #expect(channels[0].name == "Test FM")
        #expect(channels[0].url == URL(string: "https://example.com/stream")!)
    }
    @Test func 壊れたJSONはプリセットにフォールバックする() throws {
        let channels = ChannelStore.load(configURL: try tempFile("{not json"))
        #expect(channels == ChannelStore.presets)
    }
    @Test func 空配列JSONはプリセットにフォールバックする() throws {
        let channels = ChannelStore.load(configURL: try tempFile("[]"))
        #expect(channels == ChannelStore.presets)
    }
    @Test func プリセットは全てhttpsでidが一意() {
        let ids = ChannelStore.presets.map(\.id)
        #expect(Set(ids).count == ids.count)
        for ch in ChannelStore.presets {
            #expect(ch.url.scheme == "https")
        }
    }
}
