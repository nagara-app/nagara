import Testing
@testable import Nagara

@Suite struct VolumeCurveTests {
    @Test func 端点は両端に一致する() {
        #expect(VolumeCurve.gain(fromSlider: 0) == 0)
        #expect(VolumeCurve.gain(fromSlider: 1) == 1)
    }
    @Test func 三乗カーブで下半分が微小音量になる() {
        #expect(abs(VolumeCurve.gain(fromSlider: 0.5) - 0.125) < 0.0001)
        #expect(abs(VolumeCurve.gain(fromSlider: 0.25) - 0.015625) < 0.0001)
    }
    @Test func 範囲外はクランプされる() {
        #expect(VolumeCurve.gain(fromSlider: -0.5) == 0)
        #expect(VolumeCurve.gain(fromSlider: 1.5) == 1)
    }
}
