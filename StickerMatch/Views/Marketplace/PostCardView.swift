import SwiftUI

/// A marketplace post card: who/where, repeated/missing numbers, note, contact.
struct PostCardView: View {
    let bundle: PostWithStickers
    /// "X km away" when location is available.
    var distanceText: String? = nil
    /// When set, shows a "Message" button (omit for your own posts).
    var onMessage: (() -> Void)? = nil
    /// Safety actions (omit for your own posts).
    var onReport: (() -> Void)? = nil
    var onBlock: (() -> Void)? = nil

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(bundle.post.nickname.isEmpty ? "Anonymous" : bundle.post.nickname)
                        .font(.headline)
                    Label(bundle.post.city.isEmpty ? "Unknown city" : bundle.post.city,
                          systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let distanceText {
                        Label(distanceText, systemImage: "location.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tint)
                            .padding(.top, 1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if onReport != nil || onBlock != nil {
                        Menu {
                            if let onReport {
                                Button { onReport() } label: { Label("Report post", systemImage: "flag") }
                            }
                            if let onBlock {
                                Button(role: .destructive) { onBlock() } label: {
                                    Label("Block \(displayName)", systemImage: "hand.raised")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 8)
                        }
                    }
                    Text(Self.dateFormatter.string(from: bundle.post.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !bundle.post.meetingPoint.isEmpty {
                Label(bundle.post.meetingPoint, systemImage: "figure.walk")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !bundle.post.meetingTime.isEmpty {
                Label(bundle.post.meetingTime, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            numberSection(title: "Has (repeated)", numbers: bundle.repeated.map(\.stickerNumber), tint: .blue)
            numberSection(title: "Needs (missing)", numbers: bundle.missing.map(\.stickerNumber), tint: .orange)

            if !bundle.post.priceNote.isEmpty {
                Label(bundle.post.priceNote, systemImage: "tag")
                    .font(.caption)
            }

            if let onMessage {
                HStack {
                    Button(action: onMessage) {
                        Text("Message")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    Spacer()
                }
                .padding(.top, 2)
            }

            Divider()
            SafetyDisclaimerView(compact: true)
        }
        .padding(.vertical, 6)
    }

    private var displayName: String {
        bundle.post.nickname.isEmpty ? "trader" : bundle.post.nickname
    }

    private static let maxNumbersShown = 24

    @ViewBuilder
    private func numberSection(title: String, numbers: [String], tint: Color) -> some View {
        if !numbers.isEmpty {
            let shown = numbers.prefix(Self.maxNumbersShown)
            let extra = numbers.count - shown.count
            let text = shown.map { "#\($0)" }.joined(separator: "  ")
                + (extra > 0 ? "  +\(extra) more" : "")
            VStack(alignment: .leading, spacing: 4) {
                Text("\(title) · \(numbers.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(tint)
            }
        }
    }
}
