import Foundation
import Supabase

/// Authentication against Supabase Auth: native Apple Sign-In (id token) and
/// Google OAuth (web flow). Also exposes the current session/user.
final class AuthService {
    private var client: SupabaseClient { SupabaseService.shared.client }

    /// The currently signed-in user id, if any.
    var currentUserId: UUID? {
        client.auth.currentUser?.id
    }

    /// Returns the existing session if the user is already signed in.
    func currentSession() async -> Session? {
        try? await client.auth.session
    }

    /// Async stream of auth state changes (signedIn / signedOut / tokenRefreshed …).
    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        AsyncStream { continuation in
            let task = Task {
                for await change in client.auth.authStateChanges {
                    continuation.yield((change.event, change.session))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Apple (native)

    /// Completes Apple Sign-In using the identity token returned by
    /// ASAuthorizationController, plus the raw nonce used in the request.
    func signInWithApple(idToken: String, nonce: String) async throws {
        // Session updates arrive via `authStateChanges`; the return is unused.
        _ = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    // MARK: - Google (OAuth web flow)

    /// Launches Google OAuth via ASWebAuthenticationSession and completes the
    /// session. Requires the redirect scheme to be registered (see AppConfig).
    func signInWithGoogle() async throws {
        // Uses ASWebAuthenticationSession under the hood on Apple platforms.
        _ = try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: AppConfig.oauthRedirectURL
        )
    }

    // MARK: - Sign out

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Account deletion

    /// Permanently deletes the user's account + data via the `delete-account`
    /// edge function (service-role delete + FK cascades), then clears the session.
    func deleteAccount() async throws {
        try await client.functions.invoke("delete-account", options: .init(method: .post))
        try? await client.auth.signOut()
    }
}
