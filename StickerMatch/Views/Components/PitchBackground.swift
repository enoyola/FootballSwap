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

    /// A rounded "floating" card row for post/match lists: a white card on the
    /// grouped background with gaps instead of full-width separators. Use inside a
    /// `List` paired with `.listStyle(.plain)` + `.scrollContentBackground(.hidden)`.
    func floatingCardRow() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

/// A large page title pinned at the top of the content — used with
/// `.toolbar(.hidden, for: .navigationBar)` so the title sits tight to the top
/// instead of below the navigation bar's tall large-title gap. Optional trailing
/// controls share the title's row (like a large-title accessory button).
struct ScreenHeader<Trailing: View>: View {
    private let title: LocalizedStringKey
    private let trailing: Trailing

    init(_ title: LocalizedStringKey, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title.bold())
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(_ title: LocalizedStringKey) { self.init(title, trailing: { EmptyView() }) }
}

/// A rounded in-page search field — replaces the nav-bar `.searchable` on screens
/// that use a `ScreenHeader`.
struct SearchField: View {
    let prompt: LocalizedStringKey
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(prompt, text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color(.tertiarySystemFill), in: Capsule())
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
