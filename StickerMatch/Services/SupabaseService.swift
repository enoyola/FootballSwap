import Foundation
import Supabase

/// Thin singleton wrapper around the Supabase client. All services use
/// `SupabaseService.shared.client`.
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey,
            options: .init(
                auth: .init(storage: ResilientAuthStorage())
            )
        )
    }
}

/// App-level error with a user-presentable message.
struct AppError: LocalizedError, Identifiable {
    let id = UUID()
    let message: String
    var errorDescription: String? { message }

    init(_ message: String) { self.message = message }

    /// Wraps any thrown error into a friendly message.
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        return AppError(error.localizedDescription)
    }
}
