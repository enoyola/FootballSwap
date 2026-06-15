import SwiftUI

/// Centered progress indicator with an optional caption.
struct LoadingView: View {
    var message: LocalizedStringKey = "Loading…"
    @State private var spin = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "soccerball")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(.linear(duration: 1.1).repeatForever(autoreverses: false), value: spin)
                .onAppear { spin = true }
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
