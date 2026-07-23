import Foundation

struct Channel: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let url: URL
    // メニューのセクションヘッダー用。連続する同じgenreが1つの塊になる（ユーザーJSONでは省略可）
    var genre: String? = nil
}
