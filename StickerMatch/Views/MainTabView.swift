import SwiftUI

/// Main tab shell. Missing & Repeated live inside the Album tab.
struct MainTabView: View {
    let userId: UUID

    var body: some View {
        TabView {
            NavigationStack {
                AlbumView(userId: userId)
            }
            .tabItem { Label("Album", systemImage: "square.grid.3x3") }

            NavigationStack {
                MarketplaceView(userId: userId)
            }
            .tabItem { Label("Market", systemImage: "bag") }

            NavigationStack {
                MatchesView(userId: userId)
            }
            .tabItem { Label("Matches", systemImage: "arrow.left.arrow.right") }

            NavigationStack {
                ConversationsView(userId: userId)
            }
            .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right") }

            NavigationStack {
                ProfileView(userId: userId)
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}
