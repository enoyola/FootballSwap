import SwiftUI

/// My Album root: a progress hero plus browse-by-team (flags + rings).
/// Searching shows a flat list of matching players across all teams.
struct AlbumView: View {
    @StateObject private var viewModel: AlbumViewModel

    init(userId: UUID) {
        _viewModel = StateObject(wrappedValue: AlbumViewModel(userId: userId))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader("My Album")
            SearchField(prompt: "Search number or name", text: $viewModel.searchText)
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) { viewModel.errorMessage = nil }
                    .padding(.top, 8)
            }
            content
        }
        .pitchBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task { if viewModel.items.isEmpty { await viewModel.load() } }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            LoadingView(message: "Loading your album…")
        } else if viewModel.isSearching {
            searchResults
        } else {
            teamsList
        }
    }

    private var searchResults: some View {
        let results = viewModel.searchResults()
        return Group {
            if results.isEmpty {
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "No matches",
                    message: "No players match “\(viewModel.searchText)”."
                )
            } else {
                List(results) { item in
                    StickerRowView(item: item) { copies in
                        Task { await viewModel.setCopies(for: item, copies: copies) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var teamsList: some View {
        List {
            Section {
                HeroCard(
                    collected: viewModel.collectedCount,
                    total: viewModel.totalCount,
                    teamsComplete: viewModel.teamGroups.filter { $0.collected == $0.total && $0.total > 0 }.count,
                    teamsTotal: viewModel.teamGroups.count
                )
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(
                    LinearGradient(
                        colors: [Color.accentColor,
                                 Color(red: 0.0, green: 0.47, blue: 0.96)], // icon blue
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            }

            Section("Teams") {
                ForEach(viewModel.teamGroups) { team in
                    NavigationLink {
                        TeamAlbumView(team: team.name, viewModel: viewModel)
                    } label: {
                        TeamCardRow(team: team)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 0, for: .scrollContent)
    }
}

private struct HeroCard: View {
    let collected: Int
    let total: Int
    let teamsComplete: Int
    let teamsTotal: Int

    private var fraction: Double { total == 0 ? 0 : Double(collected) / Double(total) }
    private var percent: Int { Int((fraction * 100).rounded()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "soccerball")
                Text("ROAD TO 2026")
                    .tracking(1.5)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.85))

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(collected)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                Text("/ \(total) stickers")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("\(percent)%")
                    .font(.title2.weight(.bold))
            }
            .foregroundStyle(.white)

            ProgressView(value: fraction)
                .tint(.white)

            Text("\(teamsComplete) of \(teamsTotal) teams complete")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.vertical, 4)
    }
}

private struct TeamCardRow: View {
    let team: TeamGroup

    private var fraction: Double { team.total == 0 ? 0 : Double(team.collected) / Double(team.total) }

    var body: some View {
        HStack(spacing: 12) {
            FlagView(team: team.name, height: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(CountryFlag.localizedName(for: team.name)).font(.body.weight(.semibold))
                if !team.subtitle.isEmpty {
                    Text(team.subtitle)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("\(team.collected)/\(team.total)")
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(.secondary)
            if team.total > 0 && team.collected == team.total {
                Image(systemName: "trophy.fill")
                    .font(.body)
                    .foregroundStyle(.yellow)
            } else {
                ProgressRing(progress: fraction)
            }
        }
        .padding(.vertical, 4)
    }
}
