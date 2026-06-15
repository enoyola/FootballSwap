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
}
