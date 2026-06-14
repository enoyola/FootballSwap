import Foundation

/// A view-friendly join of a catalog `Sticker` with the current user's status.
/// If the user has never touched a sticker, status defaults to `.missing`.
struct AlbumItem: Identifiable, Hashable {
    let sticker: Sticker
    var status: StickerStatus
    var repeatedQty: Int

    var id: UUID { sticker.id }

    /// Copies owned, derived from status: 0 = missing, 1 = have, 2+ = repeated.
    var copies: Int {
        switch status {
        case .missing:  return 0
        case .have:     return 1
        case .repeated: return max(2, repeatedQty)
        }
    }

    init(sticker: Sticker, userSticker: UserSticker?) {
        self.sticker = sticker
        self.status = userSticker?.status ?? .missing
        self.repeatedQty = userSticker?.repeatedQty ?? 0
    }

    /// Convenience text for matching searches (number + name).
    func matches(searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        let needle = searchText.lowercased()
        return sticker.number.lowercased().contains(needle)
            || sticker.playerName.lowercased().contains(needle)
    }
}
