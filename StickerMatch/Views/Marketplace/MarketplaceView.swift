import SwiftUI
import UIKit

/// Marketplace: active posts sorted by distance ("near me") when location is
/// granted, otherwise scoped to the user's profile country. Search by sticker
/// number; tap your own post to edit; + creates a new one.
struct MarketplaceView: View {
    let userId: UUID
    @StateObject private var viewModel: MarketplaceViewModel
    @StateObject private var location = LocationService()
    @Environment(\.openURL) private var openURL
    @State private var editorTarget: EditorTarget?
    @State private var chatRoute: ChatRoute?
    @State private var showMyPosts = false
    @State private var reportTarget: ReportTarget?
    private let safety = SafetyService()

    init(userId: UUID) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: MarketplaceViewModel(userId: userId))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) { viewModel.errorMessage = nil }
                    .padding(.top, 8)
            }
            scopeBar
            content
        }
        .pitchBackground()
        .navigationTitle("Marketplace")
        .navigationDestination(item: $chatRoute) { route in
            ChatView(conversationId: route.conversationId, currentUserId: userId,
                     otherUserId: route.otherUserId, title: route.title)
        }
        .searchable(text: $viewModel.numberSearch, prompt: "Search sticker number")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("My posts") { showMyPosts = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { editorTarget = .new } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editorTarget, onDismiss: { Task { await reload() } }) { target in
            NavigationStack {
                switch target {
                case .new:
                    CreateEditPostView(userId: userId, editingPost: nil)
                case .edit(let bundle):
                    CreateEditPostView(userId: userId, editingPost: bundle)
                }
            }
        }
        .sheet(isPresented: $showMyPosts, onDismiss: { Task { await reload() } }) {
            NavigationStack { MyPostsView(userId: userId) }
        }
        .sheet(item: $reportTarget) { target in
            ReportView(currentUserId: userId, target: target)
        }
        .task {
            if location.authorizationStatus == .notDetermined { location.requestPermission() }
            if viewModel.posts.isEmpty { await reload() }
        }
        .onChange(of: location.authorizationStatus) { _, _ in Task { await reload() } }
        .refreshable { await reload() }
    }

    private func reload() async {
        let coordinate = await location.currentLocation()
        await viewModel.load(userCoordinate: coordinate, locationDenied: location.isDenied)
    }

    @ViewBuilder
    private var scopeBar: some View {
        if viewModel.hasLocation {
            Picker("Distance", selection: $viewModel.radius) {
                ForEach(DistanceRadius.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
        } else if location.isDenied {
            HStack(spacing: 8) {
                Image(systemName: "location.slash")
                Text(viewModel.myCountry.isEmpty
                     ? "Enable location to see trades near you."
                     : "Showing \(CountryCatalog.name(for: viewModel.myCountry) ?? "your country"). Turn on location for nearby trades.")
                    .font(.caption)
                Spacer(minLength: 8)
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.posts.isEmpty {
            LoadingView(message: "Loading posts…")
        } else {
            let posts = viewModel.filteredPosts()
            if posts.isEmpty {
                EmptyStateView(
                    systemImage: "soccerball",
                    title: "No posts nearby",
                    message: "Try a wider radius, or tap + to publish your repeated and missing stickers."
                )
            } else {
                List(posts) { bundle in
                    PostCardView(
                        bundle: bundle,
                        distanceText: viewModel.distanceText(for: bundle.post),
                        onMessage: { openChat(with: bundle.post) },
                        onReport: { reportTarget = reportTargetFor(bundle.post) },
                        onBlock: { Task { await block(bundle.post) } }
                    )
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func reportTargetFor(_ post: Post) -> ReportTarget {
        ReportTarget(
            reportedUserId: post.userId,
            reportedName: post.nickname.isEmpty ? "Trader" : post.nickname,
            postId: post.id
        )
    }

    private func block(_ post: Post) async {
        do {
            try await safety.block(blockerId: userId, blockedId: post.userId,
                                   nickname: post.nickname.isEmpty ? "Trader" : post.nickname)
            await reload()
        } catch {
            viewModel.errorMessage = AppError.from(error).message
        }
    }

    private func openChat(with post: Post) {
        Task {
            if let conversationId = await viewModel.startConversation(with: post.userId) {
                chatRoute = ChatRoute(
                    conversationId: conversationId,
                    otherUserId: post.userId,
                    title: post.nickname.isEmpty ? "Trader" : post.nickname
                )
            }
        }
    }

    private enum EditorTarget: Identifiable {
        case new
        case edit(PostWithStickers)

        var id: String {
            switch self {
            case .new: return "new"
            case .edit(let bundle): return bundle.id.uuidString
            }
        }
    }
}
