import SwiftUI

/// Renders a country's flag by loading a public-domain image from flagcdn.com.
/// Works in the Simulator and on device (unlike emoji flags, which the Simulator
/// can't render). No bundled assets; images are fetched on demand and cached by
/// URLCache. Falls back to a neutral placeholder while loading / on failure.
struct FlagView: View {
    private let code: String?
    private let height: CGFloat

    /// Flag for a team/country name (mapped via `CountryFlag`).
    init(team: String, height: CGFloat = 26) {
        self.code = CountryFlag.code(for: team)
        self.height = height
    }

    /// Flag for an ISO alpha-2 country code directly (e.g. "MX").
    init(countryCode: String?, height: CGFloat = 26) {
        self.code = countryCode?.lowercased()
        self.height = height
    }

    private var width: CGFloat { height * 4 / 3 }

    private var url: URL? {
        guard let code, !code.isEmpty else { return nil }
        return URL(string: "https://flagcdn.com/w160/\(code).png") // w160 = crisp on retina
    }

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 0.5)
        )
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.secondary.opacity(0.15))
    }
}
