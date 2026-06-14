import SwiftUI

/// Subtle "stadium pitch" gradient used as the app's themed background instead
/// of flat black. Pair with `.scrollContentBackground(.hidden)` on Lists/Forms
/// so it shows through.
struct PitchBackground: View {
    var body: some View {
        // Neutral light "album page" canvas (no green wash). The subtle system
        // gray lets white cards separate cleanly; color comes from the accent,
        // flags, and the hero card.
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }
}

extension View {
    /// Applies the pitch background behind a screen (use on the root container).
    func pitchBackground() -> some View {
        background(PitchBackground())
    }
}
