import UIKit
import UserNotifications
import Supabase

/// App delegate for APNs: registers for remote notifications, forwards the
/// device token to `PushManager`, and routes notification taps to the right
/// conversation via `AppRouter`.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { await PushManager.shared.handleDeviceToken(token) }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("APNs registration failed: \(error.localizedDescription)")
        #endif
    }

    /// Show a banner even when the app is foregrounded.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions { [.banner, .sound, .badge] }

    /// A tap on the notification deep-links to that conversation.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        guard let raw = info["conversation_id"] as? String, let id = UUID(uuidString: raw) else { return }
        await MainActor.run {
            AppRouter.shared.selectedTab = 3
            AppRouter.shared.openConversationId = id
        }
    }
}

/// Coordinates push permission, APNs registration, and syncing the device
/// token to Supabase for the signed-in user.
@MainActor
final class PushManager {
    static let shared = PushManager()
    private let tokens = DeviceTokenService()
    private var deviceToken: String?
    private var userId: UUID?

    private init() {}

    /// On sign-in: ask permission (once), register with APNs, and sync the token.
    func onSignIn(userId: UUID) {
        self.userId = userId
        Task {
            let center = UNUserNotificationCenter.current()
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            guard granted else { return }
            UIApplication.shared.registerForRemoteNotifications()
            if let deviceToken { try? await tokens.register(token: deviceToken, userId: userId) }
        }
    }

    /// On sign-out: drop this device's token so pushes stop, and clear the badge.
    func onSignOut() {
        let token = deviceToken
        userId = nil
        Task {
            if let token { try? await tokens.unregister(token: token) }
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }

    /// APNs delivered a device token; store it and sync if a user is known.
    func handleDeviceToken(_ token: String) {
        deviceToken = token
        if let userId { Task { try? await tokens.register(token: token, userId: userId) } }
    }
}

/// Persists the APNs device token via SECURITY DEFINER RPCs (so a device that
/// switches accounts re-points its token to the new owner).
struct DeviceTokenService {
    private var client: SupabaseClient { SupabaseService.shared.client }

    func register(token: String, userId: UUID) async throws {
        _ = try await client
            .rpc("register_device_token", params: ["p_token": token, "p_platform": "ios"])
            .execute()
    }

    func unregister(token: String) async throws {
        _ = try await client
            .rpc("unregister_device_token", params: ["p_token": token])
            .execute()
    }
}
