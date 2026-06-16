import Foundation
@testable import StickerMatch

/// Small factories for building model values in tests.
enum Fixtures {
    static func sticker(_ number: String,
                        name: String = "Player",
                        team: String = "Team",
                        category: String = "UEFA") -> Sticker {
        Sticker(id: UUID(), number: number, playerName: name, teamText: team, category: category)
    }

    /// An album item with an explicit status (and copies for `.repeated`).
    static func albumItem(_ number: String, status: StickerStatus, qty: Int = 0) -> AlbumItem {
        var item = AlbumItem(sticker: sticker(number), userSticker: nil)
        item.status = status
        item.repeatedQty = qty
        return item
    }

    static func postSticker(_ number: String, kind: PostStickerKind) -> PostSticker {
        PostSticker(id: UUID(), postId: UUID(), stickerId: UUID(),
                    kind: kind, stickerNumber: number, playerName: "Player \(number)")
    }

    static func post(nickname: String = "Trader") -> Post {
        Post(id: UUID(), userId: UUID(), nickname: nickname, city: "City", country: "SV",
             latitude: nil, longitude: nil, meetingPoint: "", meetingTime: "", priceNote: "",
             contactMethod: "", createdAt: Date(), expiresAt: Date().addingTimeInterval(7 * 86_400))
    }

    static func postWith(repeated: [String], missing: [String],
                         nickname: String = "Trader") -> PostWithStickers {
        let lines = repeated.map { postSticker($0, kind: .repeated) }
                  + missing.map { postSticker($0, kind: .missing) }
        return PostWithStickers(post: post(nickname: nickname), stickers: lines)
    }
}
