import SwiftUI

/// Identifies who/what is being reported (drives the report sheet).
struct ReportTarget: Identifiable {
    let id = UUID()
    let reportedUserId: UUID
    let reportedName: String
    var postId: UUID? = nil
}

/// Report sheet: pick a reason, add optional context, submit.
struct ReportView: View {
    let currentUserId: UUID
    let target: ReportTarget
    var onSubmitted: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var reason: ReportReason = .spam
    @State private var note = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let service = SafetyService()

    var body: some View {
        NavigationStack {
            Form {
                if let errorMessage {
                    Section { ErrorBanner(message: errorMessage) { self.errorMessage = nil } }
                        .listRowInsets(EdgeInsets())
                }

                Section("Reason") {
                    Picker("Reason", selection: $reason) {
                        ForEach(ReportReason.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Details (optional)") {
                    TextField("Add any context…", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Text("You're reporting \(target.reportedName). Reports are reviewed by our team. You can also block this person to stop all contact.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") { Task { await submit() } }
                        .disabled(isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await service.report(
                reporterId: currentUserId,
                reportedUserId: target.reportedUserId,
                postId: target.postId,
                reason: reason,
                note: note
            )
            onSubmitted()
            dismiss()
        } catch {
            errorMessage = AppError.from(error).message
        }
    }
}
