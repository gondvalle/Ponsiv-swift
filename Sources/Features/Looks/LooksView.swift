import SwiftUI
#if os(iOS)
import PhotosUI
#endif
import Core
import UIComponents

public struct LooksView: View {
    @EnvironmentObject private var appModel: AppViewModel
    let onOpenLook: (Look) -> Void
    let onEditLook: (Look) -> Void

    #if os(iOS)
    @State private var pickerItem: PhotosPickerItem?
    #endif
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    public init(onOpenLook: @escaping (Look) -> Void, onEditLook: @escaping (Look) -> Void) {
        self.onOpenLook = onOpenLook
        self.onEditLook = onEditLook
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(appModel.looks) { look in
                    lookCard(look)
                }
            }
            .padding(16)
        }
        .navigationTitle("Looks")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(isProcessing)
            }
            #endif
        }
        #if os(iOS)
        .onChange(of: pickerItem) { newValue in
            guard let item = newValue else { return }
            Task { await importLook(from: item) }
        }
        #endif
        .alert("No se pudo crear el look", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), actions: {
            Button("Aceptar", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "Inténtalo de nuevo")
        })
    }

    @ViewBuilder
    private func lookCard(_ look: Look) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RemoteImageView(url: appModel.lookCoverURL(look), cornerRadius: 16)
                .frame(height: 240)
            Text(look.title)
                .font(.headline)
                .lineLimit(1)
            Text("Por \(look.author.name)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture { onOpenLook(look) }
        .contextMenu {
            Button("Editar") { onEditLook(look) }
            Button("Eliminar", role: .destructive) { appModel.deleteLook(id: look.id) }
        }
    }

    #if os(iOS)
    private func importLook(from item: PhotosPickerItem) async {
        guard let user = appModel.user else { return }
        isProcessing = true
        defer { isProcessing = false }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
                try data.write(to: tmpURL)
                let author = Look.Author(name: user.name, avatarPath: user.avatarPath)
                let result = await appModel.createLook(title: "Mi look", coverSourceURL: tmpURL, author: author, description: nil)
                if case let .failure(error) = result {
                    errorMessage = error.localizedDescription
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    #endif
}
