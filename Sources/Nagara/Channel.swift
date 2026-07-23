import Foundation

struct Channel: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let url: URL
}
