import Foundation

/// Distance scope shared by the Marketplace and Matches "near me" filters.
enum DistanceRadius: String, CaseIterable, Identifiable {
    case km50, km100, km250, country

    var id: String { rawValue }

    var label: String {
        switch self {
        case .km50: return "50 km"
        case .km100: return "100 km"
        case .km250: return "250 km"
        case .country: return String(localized: "Country")
        }
    }

    /// Max distance in meters, or nil for the whole country (no distance cap).
    var meters: Double? {
        switch self {
        case .km50: return 50_000
        case .km100: return 100_000
        case .km250: return 250_000
        case .country: return nil
        }
    }
}
