import Foundation
import Supabase

/// Auth storage that prefers the Keychain but falls back to `UserDefaults` when
/// the Keychain is unavailable.
///
/// The Keychain needs a valid `application-identifier` entitlement, which only
/// exists in a code-signed build. An unsigned / ad-hoc simulator build (e.g.
/// `xcodebuild ... CODE_SIGNING_ALLOWED=NO`) has no entitlements, so Keychain
/// calls fail with `errSecMissingEntitlement` — which would silently drop the
/// PKCE code verifier and break OAuth sign-in. Falling back to UserDefaults
/// keeps those dev builds working; properly signed builds always use the
/// secure Keychain path.
struct ResilientAuthStorage: AuthLocalStorage {
    private let keychain = KeychainLocalStorage()
    private let defaults = UserDefaults.standard

    private func fallbackKey(_ key: String) -> String { "sb-fallback-\(key)" }

    func store(key: String, value: Data) throws {
        do {
            try keychain.store(key: key, value: value)
        } catch {
            defaults.set(value, forKey: fallbackKey(key))
        }
    }

    func retrieve(key: String) throws -> Data? {
        if let data = try? keychain.retrieve(key: key) {
            return data
        }
        return defaults.data(forKey: fallbackKey(key))
    }

    func remove(key: String) throws {
        try? keychain.remove(key: key)
        defaults.removeObject(forKey: fallbackKey(key))
    }
}
