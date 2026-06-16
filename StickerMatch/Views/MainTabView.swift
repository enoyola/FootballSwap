import SwiftUI

/// Main tab shell. Missing & Repeated live inside the Album tab.
struct MainTabView: View {
    let userId: UUID

    var body: some View {
        TabView {
            NavigationStack {
                AlbumView(userId: userId)
            }
            .tint(.blue)
            .tabItem { Label("Album", systemImage: "square.grid.3x3") }

            NavigationStack {
                MarketplaceView(userId: userId)
            }
            .tint(.blue)
            .tabItem { Label("Market", systemImage: "bag") }

            NavigationStack {
                MatchesView(userId: userId)
            }
            .tint(.blue)
            .tabItem { Label("Swap", systemImage: "arrow.left.arrow.right") }

            NavigationStack {
                ConversationsView(userId: userId)
            }
            .tint(.blue)
            .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right") }

            NavigationStack {
                ProfileView(userId: userId)
            }
            .tint(.blue)
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(Color("AccentColor")) // keep the tab bar green; content tints itself blue
    }
}
