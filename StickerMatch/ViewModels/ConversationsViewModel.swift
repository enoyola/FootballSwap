import Foundation

/// Drives the Messages inbox.
@MainActor
final class ConversationsViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let userId: UUID
    private let service: MessagingService

    init(userId: UUID, service: MessagingService = MessagingService()) {
        self.userId = userId
        self.service = service
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            conversations = try await service.fetchConversations(userId: userId)
        } catch {
            errorMessage = AppError.from(error).message
        }
    }
}
