import Foundation
import AuthenticationServices
import CryptoKit

/// App-wide authentication state and sign-in flows (Apple + Google).
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var userId: UUID?

    private let authService = AuthService()
    private var currentNonce: String?

    init() {
        Task { await bootstrap() }
    }

    /// Restore any existing session, then observe future auth changes.
    private func bootstrap() async {
        if let session = await authService.currentSession() {
            apply(userId: session.user.id)
        }
        for await change in authService.authStateChanges {
            switch change.event {
            case .signedIn, .tokenRefreshed, .userUpdated, .initialSession:
                apply(userId: change.session?.user.id)
            case .signedOut:
                apply(userId: nil)
            default:
                break
            }
        }
    }

    private func apply(userId: UUID?) {
        self.userId = userId
        self.isAuthenticated = userId != nil
    }

    // MARK: - Apple Sign-In

    /// Configure the ASAuthorization request (called by SignInWithAppleButton).
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    /// Handle the result from SignInWithAppleButton.
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            // User cancelling is not an error worth surfacing loudly.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = AppError.from(error).message
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                errorMessage = "Could not read Apple credentials. Please try again."
                return
            }
            Task { await signInWithApple(idToken: idToken, nonce: nonce) }
        }
    }

    private func signInWithApple(idToken: String, nonce: String) async {
        await run { try await self.authService.signInWithApple(idToken: idToken, nonce: nonce) }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() {
        Task { await run { try await self.authService.signInWithGoogle() } }
    }

    // MARK: - Sign out

    func signOut() {
        Task { await run { try await self.authService.signOut() } }
    }

    /// Permanently deletes the account; auth state flips to signed-out on success.
    func deleteAccount() {
        Task { await run { try await self.authService.deleteAccount() } }
    }

    // MARK: - Helpers

    private func run(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await operation()
        } catch {
            errorMessage = AppError.from(error).message
        }
    }

    // MARK: - Nonce (for Apple Sign-In replay protection)

    private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess { continue }
            if random < UInt8(charset.count) {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
