import SwiftUI

/// Searchable list of all world countries; writes the chosen ISO code back.
struct CountryPickerView: View {
    @Binding var selectedCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [CountryCatalog.Country] {
        query.isEmpty
            ? CountryCatalog.all
            : CountryCatalog.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List(results) { country in
                Button {
                    selectedCode = country.code
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        FlagView(countryCode: country.code, height: 18)
                        Text(country.name).foregroundStyle(.primary)
                        Spacer()
                        if country.code == selectedCode {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search country")
            .navigationTitle("Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
