import Foundation

/// A team and its catalog items (used by the Album's browse-by-team view).
struct TeamGroup: Identifiable {
    let name: String
    let items: [AlbumItem]
    var id: String { name }
    var total: Int { items.count }
    var collected: Int { items.filter { $0.status != .missing }.count }
    /// Confederation/category label (shared across a team).
    var subtitle: String { items.first?.sticker.category ?? "" }
}

/// Drives the Album screen (browse-by-team) plus per-team detail. A single
/// instance is shared between the team list and the team detail view, so a
/// status change anywhere updates everywhere.
@MainActor
final class AlbumViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all, missing, have, repeated
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all:      return String(localized: "All")
            case .missing:  return String(localized: "Missing")
            case .have:     return String(localized: "Have")
            case .repeated: return String(localized: "Repeated")
            }
        }
    }

    @Published var items: [AlbumItem] = []
    @Published var searchText = ""
    @Published var filter: Filter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userId: UUID
    private let albumService: AlbumService

    init(userId: UUID, albumService: AlbumService = AlbumService()) {
        self.userId = userId
        self.albumService = albumService
    }

    var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Overall progress: stickers owned (have or repeated) vs the whole catalog.
    var collectedCount: Int { items.filter { $0.status != .missing }.count }
    var totalCount: Int { items.count }

    /// Teams (sorted by name), each with its items sorted by sticker number.
    var teamGroups: [TeamGroup] {
        Dictionary(grouping: items, by: { $0.sticker.teamText })
            .map { name, groupItems in
                TeamGroup(name: name, items: groupItems.sorted { $0.sticker.number < $1.sticker.number })
            }
            .sorted {
                CountryFlag.localizedName(for: $0.name)
                    .localizedCaseInsensitiveCompare(CountryFlag.localizedName(for: $1.name)) == .orderedAscending
            }
    }

    /// Flat search across all teams (ignores the status filter, sorted by number).
    func searchResults() -> [AlbumItem] {
        items.filter { $0.matches(searchText: searchText) }
            .sorted { $0.sticker.number < $1.sticker.number }
    }

    /// A single team's items, filtered by the active status filter.
    func items(inTeam team: String) -> [AlbumItem] {
        items.filter { $0.sticker.teamText == team && matchesStatus($0) }
    }

    private func matchesStatus(_ item: AlbumItem) -> Bool {
        switch filter {
        case .all:      return true
        case .missing:  return item.status == .missing
        case .have:     return item.status == .have
        case .repeated: return item.status == .repeated
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await albumService.fetchAlbum(userId: userId)
        } catch {
            errorMessage = AppError.from(error).message
        }
    }

    /// Set how many copies the user owns and persist it (optimistic + revert).
    /// 0 = missing, 1 = have, 2+ = repeated. Status is derived from the count.
    func setCopies(for item: AlbumItem, copies: Int) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let previous = items[index]
        let (status, qty) = StickerStatus.from(copies: copies)

        // Optimistic local update.
        items[index].status = status
        items[index].repeatedQty = qty

        do {
            let saved = try await albumService.setStatus(
                userId: userId,
                stickerId: item.sticker.id,
                status: status,
                repeatedQty: qty
            )
            items[index].status = saved.status
            items[index].repeatedQty = saved.repeatedQty
        } catch {
            items[index] = previous // revert
            errorMessage = AppError.from(error).message
        }
    }
}
