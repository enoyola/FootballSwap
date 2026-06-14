import Foundation
import Supabase

/// CRUD for marketplace posts and their sticker lines.
final class PostService {
    private var client: SupabaseClient { SupabaseService.shared.client }

    // MARK: - Reads

    /// Fetch active (non-expired) posts with their sticker lines, newest first.
    /// Pass `excludingUserId` to omit your own posts (used by Matches).
    func fetchActivePosts(excludingUserId: UUID? = nil) async throws -> [PostWithStickers] {
        var query = client
            .from("posts")
            .select()
            .gt("expires_at", value: ISO8601DateFormatter().string(from: Date()))

        if let excludingUserId {
            query = query.neq("user_id", value: excludingUserId.uuidString)
        }

        let posts: [Post] = try await query
            .order("created_at", ascending: false)
            .execute()
            .value

        return try await attachStickers(to: posts)
    }

    /// Fetch the current user's own posts (for edit/delete).
    func fetchMyPosts(userId: UUID) async throws -> [PostWithStickers] {
        let posts: [Post] = try await client
            .from("posts")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return try await attachStickers(to: posts)
    }

    /// Loads the sticker lines for a set of posts and zips them together.
    private func attachStickers(to posts: [Post]) async throws -> [PostWithStickers] {
        guard !posts.isEmpty else { return [] }
        let postIds = posts.map(\.id.uuidString)
        let lines: [PostSticker] = try await client
            .from("post_stickers")
            .select()
            .in("post_id", values: postIds)
            .execute()
            .value
        let byPost = Dictionary(grouping: lines, by: \.postId)
        return posts.map { PostWithStickers(post: $0, stickers: byPost[$0.id] ?? []) }
    }

    // MARK: - Writes

    /// Create a post and attach sticker lines built from the user's album.
    @discardableResult
    func createPost(
        userId: UUID,
        nickname: String,
        city: String,
        country: String,
        latitude: Double?,
        longitude: Double?,
        meetingPoint: String,
        meetingTime: String,
        priceNote: String,
        contactMethod: String,
        album: [AlbumItem]
    ) async throws -> Post {
        let insert = PostInsert(
            userId: userId,
            nickname: nickname,
            city: city,
            country: country,
            latitude: latitude,
            longitude: longitude,
            meetingPoint: meetingPoint,
            meetingTime: meetingTime,
            priceNote: priceNote,
            contactMethod: contactMethod
        )
        let post: Post = try await client
            .from("posts")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        try await replaceStickerLines(postId: post.id, album: album)
        return post
    }

    /// Update an existing post's fields and regenerate its sticker lines.
    func updatePost(
        postId: UUID,
        nickname: String,
        city: String,
        country: String,
        latitude: Double?,
        longitude: Double?,
        meetingPoint: String,
        meetingTime: String,
        priceNote: String,
        contactMethod: String,
        album: [AlbumItem]
    ) async throws {
        let update = PostUpdate(
            nickname: nickname,
            city: city,
            country: country,
            latitude: latitude,
            longitude: longitude,
            meetingPoint: meetingPoint,
            meetingTime: meetingTime,
            priceNote: priceNote,
            contactMethod: contactMethod
        )
        try await client
            .from("posts")
            .update(update)
            .eq("id", value: postId.uuidString)
            .execute()

        try await replaceStickerLines(postId: postId, album: album)
    }

    func deletePost(postId: UUID) async throws {
        // post_stickers rows cascade-delete with the parent post.
        try await client
            .from("posts")
            .delete()
            .eq("id", value: postId.uuidString)
            .execute()
    }

    /// Replaces all sticker lines for a post with the user's current
    /// repeated + missing stickers.
    private func replaceStickerLines(postId: UUID, album: [AlbumItem]) async throws {
        try await client
            .from("post_stickers")
            .delete()
            .eq("post_id", value: postId.uuidString)
            .execute()

        let lines: [PostStickerInsert] = album.compactMap { item in
            switch item.status {
            case .repeated:
                return PostStickerInsert(postId: postId, stickerId: item.sticker.id,
                                         kind: .repeated, stickerNumber: item.sticker.number,
                                         playerName: item.sticker.playerName)
            case .missing:
                return PostStickerInsert(postId: postId, stickerId: item.sticker.id,
                                         kind: .missing, stickerNumber: item.sticker.number,
                                         playerName: item.sticker.playerName)
            case .have:
                return nil
            }
        }

        guard !lines.isEmpty else { return }
        try await client
            .from("post_stickers")
            .insert(lines)
            .execute()
    }
}
