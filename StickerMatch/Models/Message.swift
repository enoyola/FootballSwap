import Foundation

/// A chat message (`messages`).
struct Message: Codable, Identifiable, Hashable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let body: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case body
        case createdAt = "created_at"
    }

    func isMine(currentUserId: UUID) -> Bool { senderId == currentUserId }
}

/// Payload to insert a message (id/created_at are server defaults).
struct MessageInsert: Encodable {
    let conversationId: UUID
    let senderId: UUID
    let body: String

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case body
    }
}
