import SwiftUI

/// Small colored badge representing a sticker status.
struct StatusBadge: View {
    let status: StickerStatus

    private var color: Color {
        switch status {
        case .missing:  return .orange
        case .have:     return .green
        case .repeated: return .blue
        }
    }

    var body: some View {
        Text(status.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
