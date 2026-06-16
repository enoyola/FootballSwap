import SwiftUI

/// Create or edit a marketplace post. Repeated/missing lists auto-load from the
/// user's album and are previewed (read-only here — edit them in My Album).
struct CreateEditPostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreatePostViewModel
    @State private var showDeleteConfirm = false
    @State private var showCityPicker = false

    init(userId: UUID, editingPost: PostWithStickers?) {
        _viewModel = StateObject(
            wrappedValue: CreatePostViewModel(userId: userId, editingPost: editingPost)
        )
    }

    var body: some View {
        Form {
            if let error = viewModel.errorMessage {
                Section { ErrorBanner(message: error) { viewModel.errorMessage = nil } }
                    .listRowInsets(EdgeInsets())
            }

            Section("Your details") {
                TextField("Nickname", text: $viewModel.nickname)
                Button { showCityPicker = true } label: {
                    HStack {
                        Text("City").foregroundStyle(.primary)
                        Spacer()
                        Text(viewModel.city.isEmpty ? "Select" : viewModel.city)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                TextField("Meeting point (public place)", text: $viewModel.meetingPoint)
                TextField("Meeting time (e.g. Sat 3–6pm)", text: $viewModel.meetingTime)
                TextField("Price / trade note", text: $viewModel.priceNote)
            }

            Section {
                Label("Buyers reach you through in-app messages — no phone number needed.",
                      systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Stickers you have (repeated)") {
                previewRows(viewModel.repeatedItems, empty: "No repeated stickers yet.")
            }

            Section("Stickers you need (missing)") {
                previewRows(viewModel.missingItems, empty: "No missing stickers yet.")
            }

            Section {
                SafetyDisclaimerView()
            }

            if viewModel.isEditing {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete post").frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Post" : "New Post")
        .navigationBarTitleDisplayMode(.inline)
        .tint(.blue)
        .sheet(isPresented: $showCityPicker) {
            CityPickerView { city, coordinate in
                viewModel.setCity(city, coordinate: coordinate)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.isEditing ? "Save" : "Publish") {
                    Task { await viewModel.save() }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
        .overlay {
            if viewModel.isLoading || viewModel.isSaving {
                LoadingView(message: viewModel.isSaving ? "Saving…" : "Loading…")
                    .background(.ultraThinMaterial)
            }
        }
        .confirmationDialog("Delete this post?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { Task { await viewModel.deletePost() } }
            Button("Cancel", role: .cancel) {}
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.didSave) { _, didSave in
            if didSave { dismiss() }
        }
    }

    @ViewBuilder
    private func previewRows(_ items: [AlbumItem], empty: String) -> some View {
        if items.isEmpty {
            Text(empty).font(.callout).foregroundStyle(.secondary)
        } else {
            ForEach(items) { item in
                HStack {
                    Text("#\(item.sticker.number)")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(item.sticker.playerName).font(.subheadline)
                    Spacer()
                    if item.status == .repeated && item.repeatedQty > 1 {
                        Text("×\(item.repeatedQty)").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
