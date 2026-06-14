import Foundation

enum PostStickerKind: String, Codable {
    case repeated
    case missing
}

/// A sticker line attached to a post (`post_stickers`). Number/name are
/// denormalized so the marketplace and matching never need extra joins.
struct PostSticker: Codable, Identifiable, Hashable {
    let id: UUID
    let postId: UUID
    let stickerId: UUID
    let kind: PostStickerKind
    let stickerNumber: String
    let playerName: String

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case stickerId = "sticker_id"
        case kind
        case stickerNumber = "sticker_number"
        case playerName = "player_name"
    }
}

/// Payload to insert a post sticker line (id is a server default).
struct PostStickerInsert: Encodable {
    let postId: UUID
    let stickerId: UUID
    let kind: PostStickerKind
    let stickerNumber: String
    let playerName: String

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case stickerId = "sticker_id"
        case kind
        case stickerNumber = "sticker_number"
        case playerName = "player_name"
    }
}

/// A post bundled with its sticker lines (used by Marketplace & Matches).
struct PostWithStickers: Identifiable, Hashable {
    let post: Post
    let stickers: [PostSticker]

    var id: UUID { post.id }
    var repeated: [PostSticker] { stickers.filter { $0.kind == .repeated } }
    var missing: [PostSticker] { stickers.filter { $0.kind == .missing } }
}
