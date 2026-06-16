import Foundation
import CoreLocation

/// Drives the Create/Edit Post screen. Auto-loads the user's repeated + missing
/// lists for preview and pre-fills fields from their profile.
@MainActor
final class CreatePostViewModel: ObservableObject {
    @Published var nickname = ""
    @Published var city = ""
    @Published var meetingPoint = ""
    @Published var meetingTime = ""
    @Published var priceNote = ""

    private var countryCode = ""
    private var latitude: Double?
    private var longitude: Double?

    /// Sets the city and its resolved coordinate (from the city picker).
    func setCity(_ city: String, coordinate: CLLocationCoordinate2D?) {
        self.city = city
        latitude = coordinate?.latitude
        longitude = coordinate?.longitude
    }

    @Published private(set) var repeatedItems: [AlbumItem] = []
    @Published private(set) var missingItems: [AlbumItem] = []

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didSave = false

    private let userId: UUID
    private let editingPost: Post?
    private var album: [AlbumItem] = []

    private let postService: PostService
    private let profileService: ProfileService
    private let albumService: AlbumService

    var isEditing: Bool { editingPost != nil }

    init(
        userId: UUID,
        editingPost: PostWithStickers? = nil,
        postService: PostService = PostService(),
        profileService: ProfileService = ProfileService(),
        albumService: AlbumService = AlbumService()
    ) {
        self.userId = userId
        self.editingPost = editingPost?.post
        self.postService = postService
        self.profileService = profileService
        self.albumService = albumService

        if let post = editingPost?.post {
            nickname = post.nickname
            city = post.city
            countryCode = post.country
            latitude = post.latitude
            longitude = post.longitude
            meetingPoint = post.meetingPoint
            meetingTime = post.meetingTime
            priceNote = post.priceNote
        }
    }

    /// Loads album (for repeated/missing preview) and, on a new post, prefills
    /// contact fields from the profile.
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            album = try await albumService.fetchAlbum(userId: userId)
            repeatedItems = album.filter { $0.status == .repeated }
            missingItems = album.filter { $0.status == .missing }

            if !isEditing, let profile = try await profileService.fetchProfile(userId: userId) {
                nickname = profile.nickname ?? ""
                city = profile.city ?? ""
                countryCode = profile.country ?? ""
                meetingPoint = profile.meetingPoint ?? ""
            }
        } catch {
            errorMessage = AppError.from(error).message
        }
    }

    var canSave: Bool {
        !city.trimmingCharacters(in: .whitespaces).isEmpty
            && (!repeatedItems.isEmpty || !missingItems.isEmpty)
    }

    func save() async {
        guard canSave else {
            errorMessage = String(localized: "Add a city and at least one repeated or missing sticker.")
            return
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            await resolveCoordinateIfNeeded()
            if let editingPost {
                try await postService.updatePost(
                    postId: editingPost.id,
                    nickname: nickname, city: city, country: countryCode,
                    latitude: latitude, longitude: longitude, meetingPoint: meetingPoint,
                    meetingTime: meetingTime, priceNote: priceNote,
                    contactMethod: "", album: album
                )
            } else {
                try await postService.createPost(
                    userId: userId,
                    nickname: nickname, city: city, country: countryCode,
                    latitude: latitude, longitude: longitude, meetingPoint: meetingPoint,
                    meetingTime: meetingTime, priceNote: priceNote,
                    contactMethod: "", album: album
                )
            }
            didSave = true
        } catch {
            errorMessage = AppError.from(error).message
        }
    }

    /// If the city has no coordinate yet (e.g. it was pre-filled from the profile
    /// rather than picked from the autocomplete), geocode the city text so the post
    /// still gets a location and shows up in distance/radius searches.
    private func resolveCoordinateIfNeeded() async {
        guard latitude == nil || longitude == nil else { return }
        let trimmed = city.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let placemark = try? await CLGeocoder().geocodeAddressString(trimmed).first,
           let location = placemark.location {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            if countryCode.isEmpty, let iso = placemark.isoCountryCode {
                countryCode = iso.uppercased()
            }
        }
    }

    func deletePost() async {
        guard let editingPost else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await postService.deletePost(postId: editingPost.id)
            didSave = true
        } catch {
            errorMessage = AppError.from(error).message
        }
    }
}
