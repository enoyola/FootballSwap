import Foundation

/// A 1:1 conversation between two users (`conversations`). Nicknames are
/// snapshotted so we can show the partner without reading their private profile.
struct Conversation: Codable, Identifiable, Hashable {
    let id: UUID
    let userA: UUID
    let userB: UUID
    let nicknameA: String
    let nicknameB: String
    let lastMessageAt: Date
    let lastMessagePreview: String

    enum CodingKeys: String, CodingKey {
        case id
        case userA = "user_a"
        case userB = "user_b"
        case nicknameA = "nickname_a"
        case nicknameB = "nickname_b"
        case lastMessageAt = "last_message_at"
        case lastMessagePreview = "last_message_preview"
    }

    func otherUserId(currentUserId: UUID) -> UUID {
        currentUserId == userA ? userB : userA
    }

    func otherNickname(currentUserId: UUID) -> String {
        let name = currentUserId == userA ? nicknameB : nicknameA
        return name.isEmpty ? "Trader" : name
    }
}
