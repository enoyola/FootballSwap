import SwiftUI

/// Messages inbox: list of conversations, newest activity first.
struct ConversationsView: View {
    let userId: UUID
    @StateObject private var viewModel: ConversationsViewModel

    init(userId: UUID) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: ConversationsViewModel(userId: userId))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader("Messages")
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) { viewModel.errorMessage = nil }
                    .padding(.top, 8)
            }
            content
        }
        .pitchBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.conversations.isEmpty {
            LoadingView(message: "Loading messages…")
        } else if viewModel.conversations.isEmpty {
            EmptyStateView(
                systemImage: "bubble.left.and.bubble.right",
                title: "No messages yet",
                message: "Tap “Message” on a post or match to start a chat."
            )
        } else {
            List(viewModel.conversations) { conversation in
                NavigationLink(value: ChatRoute(
                    conversationId: conversation.id,
                    otherUserId: conversation.otherUserId(currentUserId: userId),
                    title: conversation.otherNickname(currentUserId: userId)
                )) {
                    ConversationRow(conversation: conversation, currentUserId: userId)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

private struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: UUID

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(conversation.otherNickname(currentUserId: currentUserId))
                    .font(.body.weight(.semibold))
                Text(conversation.lastMessagePreview.isEmpty ? "No messages yet" : conversation.lastMessagePreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(Self.relativeFormatter.localizedString(for: conversation.lastMessageAt, relativeTo: Date()))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
