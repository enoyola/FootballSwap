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
            #if DEBUG
            // Unsigned simulator/dev builds have no Keychain entitlement; fall back
            // so OAuth/session still works. Release builds must NOT weaken storage.
            defaults.set(value, forKey: fallbackKey(key))
            #else
            throw error // fail closed: never persist session material in UserDefaults
            #endif
        }
    }

    func retrieve(key: String) throws -> Data? {
        if let data = try? keychain.retrieve(key: key) {
            return data
        }
        #if DEBUG
        return defaults.data(forKey: fallbackKey(key))
        #else
        return nil
        #endif
    }

    func remove(key: String) throws {
        try? keychain.remove(key: key)
        // Always clear any stale dev-fallback value (also scrubs it in Release).
        defaults.removeObject(forKey: fallbackKey(key))
    }
}
