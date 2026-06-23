import Foundation
import CoreLocation

/// Drives the Matches screen: possible trades against active posts, ranked by
/// score and (when location is available) limited to a distance radius —
/// falling back to the user's profile country when location is off.
@MainActor
final class MatchesViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var radius: DistanceRadius = .km100
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published private(set) var userCoordinate: CLLocationCoordinate2D?
    @Published private(set) var locationDenied = false
    @Published private(set) var myCountry = ""

    var hasLocation: Bool { userCoordinate != nil }

    private let userId: UUID
    private let matchService: MatchService
    private let messagingService: MessagingService
    private let profileService: ProfileService

    init(userId: UUID,
         matchService: MatchService = MatchService(),
         messagingService: MessagingService = MessagingService(),
         profileService: ProfileService = ProfileService()) {
        self.userId = userId
        self.matchService = matchService
        self.messagingService = messagingService
        self.profileService = profileService
    }

    func load(userCoordinate: CLLocationCoordinate2D?, locationDenied: Bool) async {
        self.userCoordinate = userCoordinate
        self.locationDenied = locationDenied
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let matchesTask = matchService.fetchMatches(userId: userId)
            async let profileTask = profileService.fetchProfile(userId: userId)
            let (fetched, profile) = try await (matchesTask, profileTask)
            matches = fetched
            myCountry = profile?.country ?? ""

            // Fall back to the profile city for "near me" when GPS is unavailable.
            if userCoordinate == nil, let city = profile?.city {
                self.userCoordinate = await LocationService.coordinate(forCity: city)
            }
        } catch {
            errorMessage = AppError.from(error).message
        }
    }

    func startConversation(with otherUserId: UUID) async -> UUID? {
        do {
            return try await messagingService.getOrCreateConversation(otherUserId: otherUserId)
        } catch {
            errorMessage = AppError.from(error).message
            return nil
        }
    }

    // MARK: - Distance

    func distanceMeters(for match: Match) -> Double? {
        guard let userCoordinate,
              let lat = match.post.latitude, let lon = match.post.longitude else { return nil }
        let me = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let there = CLLocation(latitude: lat, longitude: lon)
        return me.distance(from: there)
    }

    func distanceText(for match: Match) -> String? {
        guard let meters = distanceMeters(for: match) else { return nil }
        let km = meters / 1000
        return km < 1 ? "Less than 1 km away" : "\(Int(km.rounded())) km away"
    }

    /// Matches kept in score order, limited by radius (or country when location off).
    func filteredMatches() -> [Match] {
        if hasLocation {
            guard let maxMeters = radius.meters else {
                // "Country" scope: matches anywhere in my country.
                return myCountry.isEmpty ? matches : matches.filter { $0.post.country == myCountry }
            }
            return matches.filter { (distanceMeters(for: $0) ?? .greatestFiniteMagnitude) <= maxMeters }
        } else if !myCountry.isEmpty {
            return matches.filter { $0.post.country == myCountry }
        }
        return matches
    }
}
