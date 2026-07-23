import Foundation
import Testing
@testable import Nagara

@Suite struct SettingsTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test func 初期値はlastChannelIDなし_sliderValueは0_5() {
        let s = Settings(defaults: freshDefaults())
        #expect(s.lastChannelID == nil)
        #expect(s.sliderValue == 0.5)
    }
    @Test func 保存した値が読み出せる() {
        let defaults = freshDefaults()
        var s = Settings(defaults: defaults)
        s.lastChannelID = "groovesalad"
        s.sliderValue = 0.2
        let reloaded = Settings(defaults: defaults)
        #expect(reloaded.lastChannelID == "groovesalad")
        #expect(reloaded.sliderValue == 0.2)
    }
}
