import Foundation

enum VolumeCurve {
    /// スライダー値(0...1)をAVPlayer.volumeに渡すゲインへ変換する。
    /// 3乗カーブ: スライダー下半分が gain 0〜0.125 に対応し、会議中の
    /// ささやき音量を細かく調整できる。
    static func gain(fromSlider x: Double) -> Float {
        let clamped = min(max(x, 0), 1)
        return Float(clamped * clamped * clamped)
    }
}
