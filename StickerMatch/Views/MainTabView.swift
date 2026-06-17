import SwiftUI

/// Main tab shell. Missing & Repeated live inside the Album tab.
struct MainTabView: View {
    let userId: UUID
    @EnvironmentObject private var router: AppRouter
    private let messaging = MessagingService()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                AlbumView(userId: userId)
            }
            .tint(.blue)
            .tabItem { Label("Album", systemImage: "square.grid.3x3") }
            .tag(0)

            NavigationStack {
                MarketplaceView(userId: userId)
            }
            .tint(.blue)
            .tabItem { Label("Market", systemImage: "bag") }
            .tag(1)

            NavigationStack {
                MatchesView(userId: userId)
            }
            .tint(.blue)
            .tabItem { Label("Swap", systemImage: "arrow.left.arrow.right") }
            .tag(2)

            MessagesTab(userId: userId)
                .tint(.blue)
                .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right") }
                .badge(router.unreadCount)
                .tag(3)

            NavigationStack {
                ProfileView(userId: userId)
            }
            .tint(.blue)
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(4)
        }
        .tint(Color("AccentColor")) // keep the tab bar green; content tints itself blue
        .onChange(of: router.selectedTab) { _, tab in
            if tab == 3 { router.unreadCount = 0 } // opening Messages clears the badge
        }
        .task(id: userId) {
            // App-wide listener: bump the unread badge for messages that arrive
            // while you're not on the Messages tab.
            for await message in messaging.incomingMessageStream() {
                if message.senderId != userId && router.selectedTab != 3 {
                    router.unreadCount += 1
                }
            }
        }
    }
}

/// The Messages tab — a navigation stack that can be deep-linked to a specific
/// chat from a tapped push notification.
private struct MessagesTab: View {
    let userId: UUID
    @EnvironmentObject private var router: AppRouter
    @State private var path: [ChatRoute] = []
    private let messaging = MessagingService()

    var body: some View {
        NavigationStack(path: $path) {
            ConversationsView(userId: userId)
                .navigationDestination(for: ChatRoute.self) { route in
                    ChatView(
                        conversationId: route.conversationId,
                        currentUserId: userId,
                        otherUserId: route.otherUserId,
                        title: route.title
                    )
                }
        }
        .onChange(of: router.openConversationId) { _, id in
            guard let id else { return }
            Task { await open(id) }
        }
    }

    private func open(_ conversationId: UUID) async {
        defer {
            router.openConversationId = nil
            router.unreadCount = 0
        }
        guard let convo = try? await messaging.fetchConversation(id: conversationId) else { return }
        path = [ChatRoute(
            conversationId: conversationId,
            otherUserId: convo.otherUserId(currentUserId: userId),
            title: convo.otherNickname(currentUserId: userId)
        )]
    }
}
