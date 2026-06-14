import SwiftUI

@main
struct StickerMatchApp: App {
    // Single auth source of truth for the whole app.
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}
