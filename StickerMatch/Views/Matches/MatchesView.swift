import SwiftUI
import UIKit

/// Matches: possible trades ranked by score, limited to nearby (or your country
/// when location is off). Tap Message to start a chat.
struct MatchesView: View {
    let userId: UUID
    @StateObject private var viewModel: MatchesViewModel
    @StateObject private var location = LocationService()
    @Environment(\.openURL) private var openURL
    @State private var chatRoute: ChatRoute?
    @State private var reportTarget: ReportTarget?
    private let safety = SafetyService()

    init(userId: UUID) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: MatchesViewModel(userId: userId))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader("Swap")

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) { viewModel.errorMessage = nil }
                    .padding(.top, 8)
            }
            scopeBar
            content
        }
        .pitchBackground()
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $chatRoute) { route in
            ChatView(conversationId: route.conversationId, currentUserId: userId,
                     otherUserId: route.otherUserId, title: route.title)
        }
        .sheet(item: $reportTarget) { target in
            ReportView(currentUserId: userId, target: target)
        }
        .task {
            if location.authorizationStatus == .notDetermined { location.requestPermission() }
            if viewModel.matches.isEmpty { await reload() }
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
                     ? "Enable location to see matches near you."
                     : "Showing \(CountryCatalog.name(for: viewModel.myCountry) ?? "your country"). Turn on location for nearby matches.")
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

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.matches.isEmpty {
            LoadingView(message: "Finding possible trades…")
        } else {
            let matches = viewModel.filteredMatches()
            if matches.isEmpty {
                EmptyStateView(
                    systemImage: "figure.soccer",
                    title: viewModel.matches.isEmpty ? "No matches yet" : "No matches nearby",
                    message: viewModel.matches.isEmpty
                        ? "Mark stickers as missing and repeated, and check back when more people post."
                        : "There are matches farther away — widen the radius to see them."
                )
            } else {
                List(matches) { match in
                    MatchRowView(
                        match: match,
                        distanceText: viewModel.distanceText(for: match),
                        onMessage: { openChat(with: match.post) },
                        onReport: { reportTarget = reportTargetFor(match.post) },
                        onBlock: { Task { await block(match.post) } }
                    )
                    .floatingCardRow()
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

private struct MatchRowView: View {
    let match: Match
    var distanceText: String? = nil
    let onMessage: () -> Void
    var onReport: (() -> Void)? = nil
    var onBlock: (() -> Void)? = nil

    private var displayName: String {
        match.post.nickname.isEmpty ? "Trader" : match.post.nickname
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(match.post.nickname.isEmpty ? "Anonymous" : match.post.nickname)
                        .font(.headline)
                    if !match.post.city.isEmpty {
                        Label(match.post.city, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let distanceText {
                        Label(distanceText, systemImage: "location.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.blue)
                            .padding(.top, 1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if onReport != nil || onBlock != nil {
                        Menu {
                            if let onReport {
                                Button { onReport() } label: { Label("Report", systemImage: "flag") }
                            }
                            if let onBlock {
                                Button(role: .destructive) { onBlock() } label: {
                                    Label("Block \(displayName)", systemImage: "hand.raised")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis").font(.callout).foregroundStyle(.secondary)
                        }
                        .tint(Color(.secondaryLabel))
                    }
                    Text("Score \(match.score)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color("AccentColor").opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Text("They have \(match.theyHaveCount) sticker\(match.theyHaveCount == 1 ? "" : "s") you need")
                .font(.subheadline)
            if !match.theyHave.isEmpty {
                Text(match.theyHave.map { "#\($0)" }.joined(separator: "  "))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.blue)
            }

            Text("You have \(match.iHaveCount) sticker\(match.iHaveCount == 1 ? "" : "s") they need")
                .font(.subheadline)
            if !match.iHave.isEmpty {
                Text(match.iHave.map { "#\($0)" }.joined(separator: "  "))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.orange)
            }

            if !match.post.meetingPoint.isEmpty {
                Label(match.post.meetingPoint, systemImage: "figure.walk")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !match.post.meetingTime.isEmpty {
                Label(match.post.meetingTime, systemImage: "clock")
                    .font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                Button(action: onMessage) {
                    Text("Message")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.blue)
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 6)
    }
}
