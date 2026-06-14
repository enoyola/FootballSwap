import SwiftUI

/// Profile → Blocked users: review and unblock.
struct BlockedUsersView: View {
    let userId: UUID

    @State private var blocks: [Block] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service = SafetyService()

    var body: some View {
        Group {
            if let errorMessage {
                ErrorBanner(message: errorMessage) { self.errorMessage = nil }
            }
            if isLoading && blocks.isEmpty {
                LoadingView(message: "Loading…")
            } else if blocks.isEmpty {
                EmptyStateView(
                    systemImage: "hand.raised",
                    title: "No blocked users",
                    message: "People you block won't see your posts or reach you, and you won't see theirs."
                )
            } else {
                List {
                    ForEach(blocks) { block in
                        HStack {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .foregroundStyle(.secondary)
                            Text(block.displayName)
                            Spacer()
                            Button("Unblock") { Task { await unblock(block) } }
                                .font(.callout.weight(.semibold))
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            blocks = try await service.fetchBlocked(blockerId: userId)
        } catch {
            errorMessage = AppError.from(error).message
        }
    }

    private func unblock(_ block: Block) async {
        do {
            try await service.unblock(blockerId: userId, blockedId: block.blockedId)
            blocks.removeAll { $0.id == block.id }
        } catch {
            errorMessage = AppError.from(error).message
        }
    }
}
