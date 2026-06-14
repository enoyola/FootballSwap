import Foundation
import Supabase

/// Reads and updates the current user's own profile.
final class ProfileService {
    private var client: SupabaseClient { SupabaseService.shared.client }

    /// Fetch the user's profile. Returns nil if the row doesn't exist yet
    /// (the DB trigger normally creates it on sign-up).
    func fetchProfile(userId: UUID) async throws -> Profile? {
        let profiles: [Profile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        return profiles.first
    }

    @discardableResult
    func updateProfile(
        userId: UUID,
        nickname: String,
        city: String,
        country: String,
        meetingPoint: String
    ) async throws -> Profile {
        let update = ProfileUpdate(
            nickname: nickname.isEmpty ? nil : nickname,
            city: city.isEmpty ? nil : city,
            country: country.isEmpty ? nil : country,
            meetingPoint: meetingPoint.isEmpty ? nil : meetingPoint
        )
        return try await client
            .from("profiles")
            .update(update)
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }
}
