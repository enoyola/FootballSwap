import Foundation
import CoreLocation

/// Drives the Marketplace: active public posts, sorted by distance ("near me")
/// when location is available, otherwise scoped to the user's profile country.
@MainActor
final class MarketplaceViewModel: ObservableObject {
    @Published var posts: [PostWithStickers] = []
    @Published var numberSearch = ""
    @Published var radius: DistanceRadius = .km100
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published private(set) var userCoordinate: CLLocationCoordinate2D?
    @Published private(set) var locationDenied = false
    @Published private(set) var myCountry = ""

    var hasLocation: Bool { userCoordinate != nil }

    private let userId: UUID
    private let postService: PostService
    private let profileService: ProfileService
    private let messagingService: MessagingService

    init(userId: UUID,
         postService: PostService = PostService(),
         profileService: ProfileService = ProfileService(),
         messagingService: MessagingService = MessagingService()) {
        self.userId = userId
        self.postService = postService
        self.profileService = profileService
        self.messagingService = messagingService
    }

    func load(userCoordinate: CLLocationCoordinate2D?, locationDenied: Bool) async {
        self.userCoordinate = userCoordinate
        self.locationDenied = locationDenied
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let postsTask = postService.fetchActivePosts(excludingUserId: userId)
            async let profileTask = profileService.fetchProfile(userId: userId)
            let (fetchedPosts, profile) = try await (postsTask, profileTask)
            posts = fetchedPosts
            myCountry = profile?.country ?? ""
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

    func distanceMeters(for post: Post) -> Double? {
        guard let userCoordinate, let lat = post.latitude, let lon = post.longitude else { return nil }
        let me = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let there = CLLocation(latitude: lat, longitude: lon)
        return me.distance(from: there)
    }

    func distanceText(for post: Post) -> String? {
        guard let meters = distanceMeters(for: post) else { return nil }
        let km = meters / 1000
        return km < 1 ? "Less than 1 km away" : "\(Int(km.rounded())) km away"
    }

    // MARK: - Filtering

    func filteredPosts() -> [PostWithStickers] {
        var result = posts.filter { bundle in
            numberSearch.isEmpty
                || bundle.stickers.contains { $0.stickerNumber.lowercased().contains(numberSearch.lowercased()) }
        }

        if hasLocation {
            if let maxMeters = radius.meters {
                // Hide far posts; posts without coordinates only show under "All".
                result = result.filter { (distanceMeters(for: $0.post) ?? .greatestFiniteMagnitude) <= maxMeters }
            }
            result.sort {
                (distanceMeters(for: $0.post) ?? .greatestFiniteMagnitude)
                    < (distanceMeters(for: $1.post) ?? .greatestFiniteMagnitude)
            }
        } else if !myCountry.isEmpty {
            result = result.filter { $0.post.country == myCountry }
        }

        return result
    }
}
