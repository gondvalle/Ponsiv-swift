import SwiftUI
import Core

public struct LookEditorView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var description: String
    let look: Look

    public init(look: Look) {
        self.look = look
        _title = State(initialValue: look.title)
        _description = State(initialValue: look.description ?? "")
    }

    public var body: some View {
        Form {
            Section("Título") {
                TextField("Título", text: $title)
            }
            Section("Descripción") {
                TextField("Descripción", text: $description)
            }
        }
        .navigationTitle("Editar look")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Guardar") { save() }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        #endif
    }

    private func save() {
        var updated = look
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.description = description.isEmpty ? nil : description
        appModel.updateLook(updated)
        dismiss()
    }
}
