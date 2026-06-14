import Foundation
import Supabase

/// Reads the shared catalog + the user's statuses, and writes status changes.
final class AlbumService {
    private var client: SupabaseClient { SupabaseService.shared.client }

    /// Fetch the full catalog (sorted by number).
    func fetchCatalog() async throws -> [Sticker] {
        try await client
            .from("stickers")
            .select()
            .order("number", ascending: true)
            .execute()
            .value
    }

    /// Fetch the current user's status rows.
    func fetchUserStickers(userId: UUID) async throws -> [UserSticker] {
        try await client
            .from("user_stickers")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    /// Build the album view (catalog joined with user statuses, default missing).
    func fetchAlbum(userId: UUID) async throws -> [AlbumItem] {
        async let catalog = fetchCatalog()
        async let user = fetchUserStickers(userId: userId)
        let (stickers, userStickers) = try await (catalog, user)
        let byStickerId = Dictionary(uniqueKeysWithValues: userStickers.map { ($0.stickerId, $0) })
        return stickers.map { AlbumItem(sticker: $0, userSticker: byStickerId[$0.id]) }
    }

    /// Upsert a status change for one sticker. Returns the saved values.
    /// Setting `.repeated` with qty 0 bumps it to 1; non-repeated forces qty 0.
    @discardableResult
    func setStatus(
        userId: UUID,
        stickerId: UUID,
        status: StickerStatus,
        repeatedQty: Int
    ) async throws -> UserSticker {
        let qty: Int
        switch status {
        case .repeated: qty = max(1, repeatedQty)
        default:        qty = 0
        }

        let payload = UserStickerUpsert(
            userId: userId,
            stickerId: stickerId,
            status: status,
            repeatedQty: qty
        )

        return try await client
            .from("user_stickers")
            .upsert(payload, onConflict: "user_id,sticker_id")
            .select()
            .single()
            .execute()
            .value
    }
}
