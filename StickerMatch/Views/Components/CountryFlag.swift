import Foundation

/// Maps a team/country name to its flag emoji (built into the system font — no
/// bundled image assets). National flags are public symbols, not team logos.
enum CountryFlag {
    private static let alpha2: [String: String] = [
        "Algeria": "DZ", "Argentina": "AR", "Australia": "AU", "Austria": "AT",
        "Belgium": "BE", "Brazil": "BR", "Canada": "CA", "Cape Verde": "CV",
        "Colombia": "CO", "Croatia": "HR", "Curacao": "CW", "Ecuador": "EC",
        "Egypt": "EG", "France": "FR", "Germany": "DE", "Ghana": "GH",
        "Haiti": "HT", "Iran": "IR", "Ivory Coast": "CI", "Japan": "JP",
        "Jordan": "JO", "Korea Republic": "KR", "Mexico": "MX", "Morocco": "MA",
        "Netherlands": "NL", "New Zealand": "NZ", "Norway": "NO", "Panama": "PA",
        "Paraguay": "PY", "Portugal": "PT", "Qatar": "QA", "Saudi Arabia": "SA",
        "Senegal": "SN", "South Africa": "ZA", "Spain": "ES", "Switzerland": "CH",
        "Tunisia": "TN", "United States": "US", "Uruguay": "UY", "Uzbekistan": "UZ"
    ]

    /// Lowercase code for flag image services (flagcdn). Subdivisions for UK nations.
    static func code(for team: String) -> String? {
        switch team {
        case "England":  return "gb-eng"
        case "Scotland": return "gb-sct"
        default:         return alpha2[team]?.lowercased()
        }
    }

    static func emoji(for team: String) -> String {
        // Subdivision flags use tag sequences (not regional-indicator pairs).
        switch team {
        case "England":  return "\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}"
        case "Scotland": return "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E0063}\u{E0074}\u{E007F}"
        default: break
        }
        guard let code = alpha2[team] else { return "\u{1F3F3}\u{FE0F}" } // white flag fallback
        let base: UInt32 = 0x1F1E6 // regional indicator 'A'
        var result = ""
        for scalar in code.unicodeScalars {
            if let flagScalar = UnicodeScalar(base + (scalar.value - 65)) {
                result.unicodeScalars.append(flagScalar)
            }
        }
        return result
    }
}
