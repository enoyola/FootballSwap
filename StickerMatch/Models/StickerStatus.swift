import Foundation

/// Status of a sticker in a user's album. Raw values match the Postgres
/// `sticker_status` enum.
enum StickerStatus: String, Codable, CaseIterable, Identifiable {
    case missing
    case have
    case repeated

    var id: String { rawValue }

    var label: String {
        switch self {
        case .missing:  return String(localized: "Missing")
        case .have:     return String(localized: "Have")
        case .repeated: return String(localized: "Repeated")
        }
    }

    /// Maps an owned-copies count to (status, repeatedQty): 0 = missing, 1 = have,
    /// 2+ = repeated (the count is stored as repeatedQty). Negatives clamp to 0.
    static func from(copies: Int) -> (status: StickerStatus, repeatedQty: Int) {
        let clamped = max(0, copies)
        switch clamped {
        case 0:  return (.missing, 0)
        case 1:  return (.have, 0)
        default: return (.repeated, clamped)
        }
    }
}
