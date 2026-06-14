import Foundation

/// Reads Supabase configuration from Info.plist keys, which are populated from
/// `Secrets.xcconfig` (see README). Keeps URL/anon key out of source control.
///
/// NOTE: xcconfig treats `//` as a comment, so we store only the host
/// (e.g. `abcdwxyz.supabase.co`) in `SUPABASE_HOST` and build the URL here.
enum AppConfig {
    static let supabaseURL: URL = {
        guard let host = infoValue(for: "SUPABASE_HOST"),
              !host.isEmpty,
              let url = URL(string: "https://\(host)") else {
            fatalError("""
            Missing/invalid SUPABASE_HOST.
            Create Config/Secrets.xcconfig from Secrets.example.xcconfig and set \
            SUPABASE_HOST to your project host (e.g. abcdwxyz.supabase.co — no https://).
            """)
        }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = infoValue(for: "SUPABASE_ANON_KEY"), !key.isEmpty else {
            fatalError("""
            Missing SUPABASE_ANON_KEY.
            Create Config/Secrets.xcconfig from Secrets.example.xcconfig and set SUPABASE_ANON_KEY.
            """)
        }
        return key
    }()

    /// OAuth redirect scheme (e.g. "stickermatch") used to return from Google sign-in.
    /// Must match a URL Type registered in the target's Info > URL Types.
    static let oauthRedirectScheme = "stickermatch"
    static var oauthRedirectURL: URL { URL(string: "\(oauthRedirectScheme)://login-callback")! }

    private static func infoValue(for key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
