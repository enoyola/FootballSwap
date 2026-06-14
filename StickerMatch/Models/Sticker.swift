import Foundation

/// A row from the global `stickers` catalog. Plain text only — no images.
struct Sticker: Codable, Identifiable, Hashable {
    let id: UUID
    let number: String
    let playerName: String
    let teamText: String
    let category: String

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case playerName = "player_name"
        case teamText = "team_text"
        case category
    }
}
