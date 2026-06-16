import SwiftUI

/// Navigation target for opening a chat (used by Marketplace/Matches buttons).
struct ChatRoute: Identifiable, Hashable {
    let conversationId: UUID
    let otherUserId: UUID
    let title: String
    var id: UUID { conversationId }
}

/// A single conversation thread: bubbles + input bar, with realtime updates.
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    let currentUserId: UUID
    let otherUserId: UUID
    let title: String

    @State private var reportTarget: ReportTarget?
    @State private var showBlockConfirm = false
    private let safety = SafetyService()

    init(conversationId: UUID, currentUserId: UUID, otherUserId: UUID, title: String) {
        self.currentUserId = currentUserId
        self.otherUserId = otherUserId
        self.title = title
        _viewModel = StateObject(
            wrappedValue: ChatViewModel(conversationId: conversationId, currentUserId: currentUserId)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) { viewModel.errorMessage = nil }
                    .padding(.top, 8)
            }

            messagesList
            inputBar
        }
        .pitchBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        reportTarget = ReportTarget(reportedUserId: otherUserId, reportedName: title)
                    } label: { Label("Report", systemImage: "flag") }
                    Button(role: .destructive) {
                        showBlockConfirm = true
                    } label: { Label("Block \(title)", systemImage: "hand.raised") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .tint(Color(.secondaryLabel))
            }
        }
        .confirmationDialog("Block \(title)?", isPresented: $showBlockConfirm, titleVisibility: .visible) {
            Button("Block", role: .destructive) { Task { await block() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't see each other's posts, matches, or messages.")
        }
        .sheet(item: $reportTarget) { target in
            ReportView(currentUserId: currentUserId, target: target)
        }
        .task {
            await viewModel.load()
            viewModel.startRealtime()
        }
        .onDisappear { viewModel.stopRealtime() }
    }

    private func block() async {
        do {
            try await safety.block(blockerId: currentUserId, blockedId: otherUserId, nickname: title)
            dismiss()
        } catch {
            viewModel.errorMessage = AppError.from(error).message
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.messages.isEmpty && !viewModel.isLoading {
                        Text("Say hello and arrange a public place to trade.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    }
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message, isMine: message.isMine(currentUserId: viewModel.currentUserId))
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            Button {
                Task { await viewModel.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

private struct MessageBubble: View {
    let message: Message
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 40) }
            Text(message.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isMine ? Color.blue : Color.secondary.opacity(0.15))
                .foregroundStyle(isMine ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if !isMine { Spacer(minLength: 40) }
        }
    }
}
