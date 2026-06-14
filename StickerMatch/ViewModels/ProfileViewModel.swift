import Foundation

/// Drives the Profile screen: edit nickname, country, city, meeting point.
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var nickname = ""
    @Published var city = ""
    @Published var countryCode = ""   // ISO alpha-2
    @Published var meetingPoint = ""

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var savedConfirmation = false

    private let userId: UUID
    private let profileService: ProfileService

    init(userId: UUID, profileService: ProfileService = ProfileService()) {
        self.userId = userId
        self.profileService = profileService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if let profile = try await profileService.fetchProfile(userId: userId) {
                nickname = profile.nickname ?? ""
                city = profile.city ?? ""
                countryCode = profile.country ?? ""
                meetingPoint = profile.meetingPoint ?? ""
            }
        } catch {
            errorMessage = AppError.from(error).message
        }
    }

    func save() async {
        isSaving = true
        errorMessage = nil
        savedConfirmation = false
        defer { isSaving = false }
        do {
            try await profileService.updateProfile(
                userId: userId,
                nickname: nickname, city: city,
                country: countryCode, meetingPoint: meetingPoint
            )
            savedConfirmation = true
        } catch {
            errorMessage = AppError.from(error).message
        }
    }
}
