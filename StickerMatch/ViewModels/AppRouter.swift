import SwiftUI

/// App-wide navigation + notification state shared between SwiftUI and the
/// `AppDelegate` (which handles APNs taps). A singleton so the delegate and the
/// view tree mutate the same instance.
@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    /// Selected tab (Album 0, Market 1, Swap 2, Messages 3, Profile 4).
    @Published var selectedTab: Int = 0
    /// Unread-message count shown as a badge on the Messages tab.
    @Published var unreadCount: Int = 0
    /// Set when a push is tapped; the Messages tab opens this conversation.
    @Published var openConversationId: UUID?

    private init() {
        #if DEBUG
        // UI/screenshot automation only: `simctl launch … -startTab <0-4>` opens
        // the app directly on that tab (no openurl confirmation dialog). Unset → 0.
        let startTab = UserDefaults.standard.integer(forKey: "startTab")
        if (0..<5).contains(startTab) { selectedTab = startTab }
        #endif
    }
}
