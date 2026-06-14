import SwiftUI

/// Your own marketplace posts — tap one to edit or delete it.
struct MyPostsView: View {
    let userId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var posts: [PostWithStickers] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service = PostService()

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                ErrorBanner(message: errorMessage) { self.errorMessage = nil }
                    .padding(.top, 8)
            }
            content
        }
        .navigationTitle("My Posts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && posts.isEmpty {
            LoadingView(message: "Loading your posts…")
        } else if posts.isEmpty {
            EmptyStateView(
                systemImage: "bag",
                title: "No posts yet",
                message: "Tap + in the Marketplace to publish your repeated and missing stickers."
            )
        } else {
            List {
                ForEach(posts) { bundle in
                    NavigationLink {
                        CreateEditPostView(userId: userId, editingPost: bundle)
                    } label: {
                        PostCardView(bundle: bundle)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await delete(bundle) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            posts = try await service.fetchMyPosts(userId: userId)
        } catch {
            errorMessage = AppError.from(error).message
        }
    }

    private func delete(_ bundle: PostWithStickers) async {
        do {
            try await service.deletePost(postId: bundle.post.id)
            posts.removeAll { $0.id == bundle.id }
        } catch {
            errorMessage = AppError.from(error).message
        }
    }
}
