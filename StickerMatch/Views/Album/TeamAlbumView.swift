import SwiftUI

/// One team's players, with the All/Missing/Have/Repeated status filter.
/// Shares the Album view model so edits propagate back to the team list.
struct TeamAlbumView: View {
    let team: String
    @ObservedObject var viewModel: AlbumViewModel

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $viewModel.filter) {
                ForEach(AlbumViewModel.Filter.allCases) { f in
                    Text(f.label).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            let items = viewModel.items(inTeam: team)
            if items.isEmpty {
                EmptyStateView(
                    systemImage: "tray",
                    title: "Nothing here",
                    message: "No stickers to show for \(team)."
                )
            } else {
                List(items) { item in
                    StickerRowView(item: item) { copies in
                        Task { await viewModel.setCopies(for: item, copies: copies) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .pitchBackground()
        .navigationTitle(CountryFlag.localizedName(for: team))
        .navigationBarTitleDisplayMode(.inline)
    }
}
