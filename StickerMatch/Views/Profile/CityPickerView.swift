import SwiftUI
import MapKit

/// Drives city search via MapKit's local-search completer (no location
/// permission needed — it's a query, not the user's position).
final class CitySearchModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func search(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            results = []
            return
        }
        completer.queryFragment = trimmed
    }

    /// Resolves a suggestion to a coordinate (nil if it can't be resolved).
    func resolveCoordinate(for completion: MKLocalSearchCompletion) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        return try? await search.start().mapItems.first?.placemark.coordinate
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}

/// City search sheet. Calls `onPick` with the chosen city name and (best-effort)
/// coordinate.
struct CityPickerView: View {
    let onPick: (_ city: String, _ coordinate: CLLocationCoordinate2D?) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = CitySearchModel()
    @State private var query = ""
    @State private var isResolving = false

    var body: some View {
        NavigationStack {
            Group {
                if query.trimmingCharacters(in: .whitespaces).count < 2 {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "Search your city",
                        message: "Start typing a city name to see suggestions."
                    )
                } else if model.results.isEmpty {
                    EmptyStateView(systemImage: "mappin.slash", title: "No matches")
                } else {
                    List(model.results, id: \.self) { result in
                        Button {
                            select(result)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title).foregroundStyle(.primary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $query, prompt: "Search city")
            .onChange(of: query) { _, newValue in model.search(newValue) }
            .navigationTitle("City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
            .overlay {
                if isResolving { LoadingView(message: "Locating…").background(.ultraThinMaterial) }
            }
        }
    }

    private func select(_ result: MKLocalSearchCompletion) {
        isResolving = true
        Task {
            let coordinate = await model.resolveCoordinate(for: result)
            isResolving = false
            onPick(result.title, coordinate)
            dismiss()
        }
    }
}
