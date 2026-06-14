import Foundation

/// A user's per-sticker status row (`user_stickers`). Private to the owner.
struct UserSticker: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let stickerId: UUID
    var status: StickerStatus
    var repeatedQty: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case stickerId = "sticker_id"
        case status
        case repeatedQty = "repeated_qty"
    }
}

/// Payload used to upsert a status change (omits the server-generated id).
struct UserStickerUpsert: Encodable {
    let userId: UUID
    let stickerId: UUID
    let status: StickerStatus
    let repeatedQty: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case stickerId = "sticker_id"
        case status
        case repeatedQty = "repeated_qty"
    }
}
