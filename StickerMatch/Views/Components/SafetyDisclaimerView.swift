import SwiftUI

/// The required safety disclaimer, shown in the marketplace and on posts.
struct SafetyDisclaimerView: View {
    static let text = "Meet only in public places. FootballSwap does not process payments, verify users, or guarantee trades."

    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "shield.lefthalf.filled")
            Text(Self.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(compact ? .caption2 : .caption)
        .foregroundStyle(.secondary)
    }
}
