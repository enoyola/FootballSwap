import SwiftUI

@main
struct StickerMatchApp: App {
    // APNs / notification handling lives in the app delegate.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // Single auth source of truth for the whole app.
    @StateObject private var authViewModel = AuthViewModel()
    // Shared navigation + unread/notification state (also used by AppDelegate).
    @StateObject private var router = AppRouter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(router)
        }
    }
}
