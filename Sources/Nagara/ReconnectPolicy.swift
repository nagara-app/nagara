import Foundation

enum ReconnectPolicy {
    static let delays: [TimeInterval] = [2, 5, 10]
    /// attempt回目(0始まり)の再接続までの待ち秒。上限超過はnil＝諦めて停止表示。
    static func delay(forAttempt n: Int) -> TimeInterval? {
        delays.indices.contains(n) ? delays[n] : nil
    }
}
