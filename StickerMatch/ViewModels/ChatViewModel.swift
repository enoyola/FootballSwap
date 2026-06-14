import Foundation

/// Drives a single chat thread: loads history, sends, and appends realtime inserts.
@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?

    let conversationId: UUID
    let currentUserId: UUID
    private let service: MessagingService
    private var realtimeTask: Task<Void, Never>?

    init(conversationId: UUID, currentUserId: UUID, service: MessagingService = MessagingService()) {
        self.conversationId = conversationId
        self.currentUserId = currentUserId
        self.service = service
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            messages = try await service.fetchMessages(conversationId: conversationId)
        } catch {
            errorMessage = AppError.from(error).message
        }
    }

    func startRealtime() {
        guard realtimeTask == nil else { return }
        realtimeTask = Task { [weak self] in
            guard let self else { return }
            for await message in service.messageStream(conversationId: conversationId) {
                self.append(message)
            }
        }
    }

    func stopRealtime() {
        realtimeTask?.cancel()
        realtimeTask = nil
    }

    func send() async {
        let body = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isSending else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            let saved = try await service.sendMessage(
                conversationId: conversationId, senderId: currentUserId, body: body
            )
            inputText = ""
            append(saved) // realtime will echo; append dedupes by id
        } catch {
            errorMessage = AppError.from(error).message
        }
    }

    /// Append keeping order by createdAt, ignoring duplicates (realtime echo).
    private func append(_ message: Message) {
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        messages.append(message)
        messages.sort { $0.createdAt < $1.createdAt }
    }
}
