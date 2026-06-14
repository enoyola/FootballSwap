import SwiftUI

/// Small circular progress gauge; shows a green check when complete.
struct ProgressRing: View {
    let progress: Double // 0...1
    var size: CGFloat = 30

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 3.5)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    clamped >= 1 ? Color.green : Color.accentColor,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            if clamped >= 1 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(.green)
            }
        }
        .frame(width: size, height: size)
    }
}
