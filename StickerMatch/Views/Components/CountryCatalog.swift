import Foundation

/// The full list of world countries (ISO alpha-2 code + localized name),
/// derived from the system region data. Used by the country picker.
enum CountryCatalog {
    struct Country: Identifiable, Hashable {
        let code: String   // ISO alpha-2, uppercase
        let name: String
        var id: String { code }
    }

    static let all: [Country] = {
        let locale = Locale.current
        return Locale.Region.isoRegions
            .map(\.identifier)
            .filter { $0.count == 2 } // 2-letter = country; 3-digit = macro-region
            .compactMap { code -> Country? in
                guard let name = locale.localizedString(forRegionCode: code) else { return nil }
                return Country(code: code, name: name)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()

    static func name(for code: String?) -> String? {
        guard let code, !code.isEmpty else { return nil }
        return Locale.current.localizedString(forRegionCode: code)
    }
}
