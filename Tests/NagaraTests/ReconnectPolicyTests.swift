import Testing
@testable import Nagara

@Suite struct ReconnectPolicyTests {
    @Test func 三回まで段階的な待ち時間を返す() {
        #expect(ReconnectPolicy.delay(forAttempt: 0) == 2)
        #expect(ReconnectPolicy.delay(forAttempt: 1) == 5)
        #expect(ReconnectPolicy.delay(forAttempt: 2) == 10)
    }
    @Test func 四回目以降はnilで諦める() {
        #expect(ReconnectPolicy.delay(forAttempt: 3) == nil)
        #expect(ReconnectPolicy.delay(forAttempt: 99) == nil)
    }
}
