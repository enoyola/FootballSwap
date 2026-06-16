import Foundation

/// Computes possible trades between my album and other users' active posts.
///
/// Matching is intentionally simple and runs client-side on already-public
/// post data (no extra privacy surface, no DB function needed for the MVP):
///   theyHave = post.repeated ∩ myMissing   (numbers they can give me)
///   iHave    = myRepeated   ∩ post.missing  (numbers I can give them)
///   score    = theyHave.count + iHave.count, keep score > 0, sort desc.
final class MatchService {
    private let albumService: AlbumService
    private let postService: PostService

    init(albumService: AlbumService = AlbumService(),
         postService: PostService = PostService()) {
        self.albumService = albumService
        self.postService = postService
    }

    func fetchMatches(userId: UUID) async throws -> [Match] {
        async let albumTask = albumService.fetchAlbum(userId: userId)
        async let postsTask = postService.fetchActivePosts(excludingUserId: userId)
        let (album, posts) = try await (albumTask, postsTask)
        return Self.computeMatches(album: album, posts: posts)
    }

    /// Pure matching (no I/O), exposed for testing:
    ///   theyHave = post.repeated ∩ myMissing, iHave = myRepeated ∩ post.missing,
    ///   score = theyHave + iHave, keep score > 0, sort by score desc.
    static func computeMatches(album: [AlbumItem], posts: [PostWithStickers]) -> [Match] {
        let myMissing = Set(album.filter { $0.status == .missing }.map { $0.sticker.number })
        let myRepeated = Set(album.filter { $0.status == .repeated }.map { $0.sticker.number })

        return posts.compactMap { bundle in
            let theyHave = Set(bundle.repeated.map(\.stickerNumber)).intersection(myMissing).sorted()
            let iHave = Set(bundle.missing.map(\.stickerNumber)).intersection(myRepeated).sorted()
            guard !theyHave.isEmpty || !iHave.isEmpty else { return nil }
            return Match(post: bundle.post, theyHave: theyHave, iHave: iHave)
        }
        .sorted { $0.score > $1.score }
    }
}
