import SwiftUI

/// Profile: edit nickname, country, city, meeting point; sign out; delete (placeholder).
struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel
    @State private var showDeleteConfirm = false
    @State private var showCountryPicker = false
    @State private var showCityPicker = false
    let userId: UUID

    init(userId: UUID) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }

    var body: some View {
        Form {
            if let error = viewModel.errorMessage {
                Section { ErrorBanner(message: error) { viewModel.errorMessage = nil } }
                    .listRowInsets(EdgeInsets())
            }

            Section("Profile") {
                TextField("Nickname", text: $viewModel.nickname)

                Button { showCountryPicker = true } label: {
                    HStack(spacing: 10) {
                        Text("Country").foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.countryCode.isEmpty {
                            FlagView(countryCode: viewModel.countryCode, height: 16)
                            Text(CountryCatalog.name(for: viewModel.countryCode) ?? viewModel.countryCode)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Select").foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                Button { showCityPicker = true } label: {
                    HStack {
                        Text("City").foregroundStyle(.primary)
                        Spacer()
                        Text(viewModel.city.isEmpty ? "Select" : viewModel.city)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                TextField("Preferred meeting point", text: $viewModel.meetingPoint)
            }

            Section {
                Button {
                    Task { await viewModel.save() }
                } label: {
                    HStack {
                        Text("Save")
                        if viewModel.isSaving { Spacer(); ProgressView() }
                        else if viewModel.savedConfirmation { Spacer(); Image(systemName: "checkmark") }
                    }
                }
                .disabled(viewModel.isSaving)
            }

            Section("Safety") {
                NavigationLink {
                    BlockedUsersView(userId: userId)
                } label: {
                    Label("Blocked users", systemImage: "hand.raised")
                }
            }

            Section("Account") {
                Button("Sign out") { auth.signOut() }
                Button("Delete account", role: .destructive) { showDeleteConfirm = true }
            }

            Section {
                SafetyDisclaimerView()
            }
        }
        .scrollContentBackground(.hidden)
        .tint(.blue)
        .pitchBackground()
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            ScreenHeader("Profile").background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCode: $viewModel.countryCode)
        }
        .sheet(isPresented: $showCityPicker) {
            CityPickerView { city, _ in viewModel.city = city }
        }
        .overlay {
            if viewModel.isLoading { LoadingView().background(.ultraThinMaterial) }
        }
        .confirmationDialog("Delete your account?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { auth.deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your album, posts, and messages. This cannot be undone.")
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.nickname) { _, _ in viewModel.savedConfirmation = false }
    }
}
