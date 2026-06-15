import SwiftUI

/// One album row: number, name, flag, derived status badge, and a single
/// "copies" stepper (0 = missing, 1 = have, 2+ = repeated).
struct StickerRowView: View {
    let item: AlbumItem
    let onCopiesChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("#\(item.sticker.number)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(item.sticker.displayName)
                    .font(.body.weight(.medium))
                Spacer()
                StatusBadge(status: item.status)
            }

            if !subtitle.isEmpty {
                HStack(spacing: 5) {
                    FlagView(team: item.sticker.teamText, height: 12)
                    Text(subtitle)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack {
                Text("Copies")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Stepper(
                    value: Binding(get: { item.copies }, set: { onCopiesChange($0) }),
                    in: 0...99
                ) {
                    Text("\(item.copies)")
                        .font(.callout.monospacedDigit().weight(.medium))
                        .frame(minWidth: 24, alignment: .trailing)
                }
                .fixedSize()
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        [CountryFlag.localizedName(for: item.sticker.teamText), item.sticker.category]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
