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

    @State private var query: String = ""
    #if os(iOS)
    @State private var pickerItem: PhotosPickerItem?
    #endif
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let columns = [GridItem(.flexible(), spacing: AppTheme.Spacing.m), GridItem(.flexible(), spacing: AppTheme.Spacing.m)]

    private var filteredLooks: [Look] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return appModel.looks
        }
        let tokens = query.lowercased().split(separator: " ")
        return appModel.looks.filter { look in
            let haystack = "\(look.title) \(look.author.name)".lowercased()
            return tokens.allSatisfy { haystack.contains($0) }
        }
    }

    public init(onOpenLook: @escaping (Look) -> Void, onEditLook: @escaping (Look) -> Void) {
        self.onOpenLook = onOpenLook
        self.onEditLook = onEditLook
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.l) {
                searchField
                looksGrid
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.vertical, AppTheme.Spacing.l)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Looks")
        .toolbar { createToolbar }
        #if os(iOS)
        .onChange(of: pickerItem) { newValue in
            guard let item = newValue else { return }
            Task { await importLook(from: item) }
        }
        #endif
        .alert("No se pudo crear el look", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Inténtalo de nuevo")
        }
    }

    private var searchField: some View {
        TextField("Buscar looks, estilos o prendas...", text: $query)
#if os(iOS)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
#endif
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, AppTheme.Spacing.m)
            .background(AppTheme.Colors.secondaryBackground, in: RoundedRectangle(cornerRadius: AppTheme.Radii.l, style: .continuous))
    }

    @ViewBuilder
    private var looksGrid: some View {
        if filteredLooks.isEmpty {
            Text("No hay looks que coincidan con tu búsqueda.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, AppTheme.Spacing.xl)
        } else {
            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.m) {
                ForEach(filteredLooks) { look in
                    lookCard(look)
                }
            }
        }
    }

    private func lookCard(_ look: Look) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            RemoteImageView(url: appModel.lookCoverURL(look), contentMode: .fill, cornerRadius: AppTheme.Radii.m)
                .frame(height: 280)
            Text(look.title)
                .font(.system(size: 14, weight: .semibold))
            Text("Por \(look.author.name)")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture { onOpenLook(look) }
        .contextMenu {
            Button("Editar") { onEditLook(look) }
            Button("Eliminar", role: .destructive) { appModel.deleteLook(id: look.id) }
        }
    }

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .automatic
        #endif
    }

    @ToolbarContentBuilder
    private var createToolbar: some ToolbarContent {
        ToolbarItem(placement: toolbarPlacement) {
            Group {
                #if os(iOS)
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(isProcessing)
                #else
                Button {
                    presentImportPanel()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(isProcessing)
                #endif
            }
        }
    }

    #if os(iOS)
    private func importLook(from item: PhotosPickerItem) async {
        guard let user = appModel.user else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                try await createLook(with: data, author: user)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    #endif

    private func createLook(with data: Data, author user: User) async throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        try data.write(to: tmpURL)
        let author = Look.Author(name: user.name, avatarPath: user.avatarPath)
        let result = await appModel.createLook(title: "Mi look", coverSourceURL: tmpURL, author: author, description: nil)
        if case .failure(let error) = result {
            errorMessage = error.localizedDescription
        } else {
            appModel.refreshLooks()
        }
    }

    #if os(macOS)
    private func presentImportPanel() {
        guard let user = appModel.user else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
            isProcessing = true
            Task {
                defer { isProcessing = false }
                do {
                    try await createLook(with: data, author: user)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    #endif
}
