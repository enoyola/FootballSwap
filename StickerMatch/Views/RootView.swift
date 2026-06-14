import SwiftUI

/// Switches between the login flow and the main app based on auth state.
struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isAuthenticated, let userId = auth.userId {
                MainTabView(userId: userId)
            } else {
                LoginView()
            }
        }
        .animation(.default, value: auth.isAuthenticated)
    }
}
