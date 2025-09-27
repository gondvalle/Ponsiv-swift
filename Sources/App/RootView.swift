import SwiftUI
import Core            // Para modelos Product, Look, User definidos en Sources/Core/Models/
import Features        // Para todas las vistas de características (Feed, Profile, etc.)
import Infrastructure  // Para servicios de infraestructura (PhotoStorage, etc.)
import UIComponents    // Para componentes de UI (TopBarView, BottomBarView, AppTheme, etc.)
#if os(iOS)
import PhotosUI        // Para selección de fotos en iOS
#endif
#if canImport(UIKit)
import UIKit           // Para funcionalidades específicas de iOS
#endif
#if os(macOS)
import AppKit          // Para funcionalidades específicas de macOS
#endif

/**
 * VISTA RAÍZ PRINCIPAL DE LA APLICACIÓN
 *
 * Esta es la vista principal que controla toda la navegación y el estado de la aplicación.
 * Gestiona los diferentes estados de carga, autenticación y funcionamiento normal.
 *
 * FUNCIONALIDADES PRINCIPALES:
 * - Gestión de estados de la app (loading, authentication, ready, error)
 * - Navegación por tabs (Feed, Explore, Looks, Cart, Profile)
 * - Navegación por stack (ProductDetail, LookDetail, Messages, etc.)
 * - Gestión de modales (crear look, logout)
 * - Integración con TopBarView y BottomBarView
 *
 * DEPENDENCIAS CRUZADAS MÁS IMPORTANTES:
 * - AppViewModel (Sources/Features/Shared/AppViewModel.swift) - Estado global de la app
 * - TopBarView (Sources/UIComponents/TopBarView.swift) - Barra superior
 * - BottomBarView (Sources/UIComponents/BottomBarView.swift) - Barra inferior
 * - FeedView (Sources/Features/Feed/FeedView.swift) - Vista principal de productos
 * - LoginView (Sources/Features/Auth/LoginView.swift) - Vista de autenticación
 * - Todas las vistas de características en Sources/Features/
 *
 * LLAMADO DESDE:
 * - PonsivApp.swift como vista principal de la aplicación
 */
public struct RootView: View {
    // MODELO GLOBAL DE LA APLICACIÓN
    @EnvironmentObject private var appModel: AppViewModel  // Inyectado desde PonsivApp.swift

    // ESTADO DE NAVEGACIÓN
    @State private var path: [AppDestination] = []         // Stack de navegación
    @State private var selectedTab: MainTab = .feed        // Tab actualmente seleccionado

    // ESTADO DE LANZAMIENTO DE FEED
    @State private var feedLaunch: FeedLaunch?             // Configuración específica del feed

    // ESTADO DE MODALES
    @State private var showCreateLookSheet = false         // Modal de crear look
    @State private var showLogoutDialog = false            // Diálogo de logout

    // ESTADO DE CREACIÓN DE LOOK
    @State private var createLookTitle: String = ""        // Título del nuevo look
    @State private var createLookDescription: String = ""  // Descripción del nuevo look
    @State private var createLookImageData: Data?          // Datos de imagen del look
    @State private var createLookError: String?            // Error en creación de look

    public init() {}

    public var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            Group {
                switch appModel.phase {
                case .loading:
                    loadingView
                case .failed(let message):
                    errorView(message: message)
                case .needsAuthentication:
                    LoginView()
                        .environmentObject(appModel)
                case .ready:
                    readyView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            if appModel.phase == .loading {
                appModel.bootstrap()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            RemoteImageView(url: AssetService().url(for: "logos/Ponsiv.png"), contentMode: .fit)
                .frame(maxWidth: 160, maxHeight: 48)
            ProgressView()
                .progressViewStyle(.circular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background.ignoresSafeArea())
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Text("Algo ha ido mal")
                .font(.title2.bold())
            Text(message)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            Button("Reintentar") { appModel.bootstrap() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background.ignoresSafeArea())
    }

    private var readyView: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom

            VStack(spacing: 0) {
                TopBarView(
                    configuration: topBarConfiguration,
                    onLogoTap: handleLogoTap,
                    onBack: handleBack,
                    onMessages: { path.append(.messages) },
                    onCreateLook: { showCreateLookSheet = true },
                    onShowMenu: { showLogoutDialog = true }
                )
                .padding(.top, safeTop)

                NavigationStack(path: $path) {
                    tabContent
                        .navigationDestination(for: AppDestination.self) { destination in
                            switch destination {
                            case .product(let product):
                                ProductDetailView(product: product)
                                    .environmentObject(appModel)
                            case .lookDetail(let looks, let start):
                                LookDetailView(looks: looks, startLook: start)
                                    .environmentObject(appModel)
                            case .lookEdit(let look):
                                LookEditorView(look: look)
                                    .environmentObject(appModel)
                            case .messages:
                                MessagesView()
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: selectedTab == .feed ? [.bottom] : [])

                BottomBarView(
                    items: MainTab.allCases.map { $0.bottomBarItem },
                    selectedID: selectedTab.rawValue,
                    cartBadgeValue: cartItemCount,
                    onSelect: { item in
                        selectedTab = MainTab(rawValue: item.id) ?? .feed
                    }
                )
                .padding(.bottom, max(safeBottom, 10))

                .background(AppTheme.Colors.surface.ignoresSafeArea(edges: .bottom))

            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
        }
        .sheet(isPresented: $showCreateLookSheet) {
            CreateLookSheet(
                imageData: $createLookImageData,
                title: $createLookTitle,
                description: $createLookDescription,
                errorMessage: $createLookError,
                onUpload: uploadLook,
                onDismiss: resetCreateLook
            )
        }
        .confirmationDialog("", isPresented: $showLogoutDialog, titleVisibility: .hidden) {
            Button("Cerrar sesión", role: .destructive) { appModel.logout() }
            Button("Cancelar", role: .cancel) { showLogoutDialog = false }
        }
    }

    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .feed:
                FeedView(onOpenDetail: { product in
                    path.append(.product(product))
                }, launch: feedLaunch)
                .environmentObject(appModel)
            case .explore:
                ExploreView(onOpenFeed: { launch in
                    feedLaunch = launch
                    selectedTab = .feed
                }, onOpenDetail: { product in
                    path.append(.product(product))
                })
                .environmentObject(appModel)
            case .looks:
                LooksView(onOpenLook: { look in
                    let subset = appModel.looks
                    if let start = subset.first(where: { $0.id == look.id }) {
                        path.append(.lookDetail(looks: subset, start: start))
                    }
                }, onEditLook: { look in
                    path.append(.lookEdit(look))
                })
                .environmentObject(appModel)
            case .cart:
                CartView(onCheckout: {
                    selectedTab = .profile
                })
                .environmentObject(appModel)
            case .profile:
                ProfileView()
                    .environmentObject(appModel)
            }
        }
    }

    private var cartItemCount: Int {
        appModel.cartItems.reduce(into: 0) { $0 += $1.quantity }
    }

    private var topBarConfiguration: TopBarView.Configuration {
        let hasBackDestination = !path.isEmpty && (path.last == .messages || isViewingLookDetail)
        return TopBarView.Configuration(
            showBack: hasBackDestination,
            showsCreateLookAction: selectedTab == .looks && path.isEmpty,
            showsProfileMenu: selectedTab == .profile && path.isEmpty
        )
    }

    private var isViewingLookDetail: Bool {
        guard let last = path.last else { return false }
        if case .lookDetail = last { return true }
        return false
    }

    private func handleLogoTap() {
        selectedTab = .feed
        feedLaunch = nil
        path.removeAll()
    }

    private func handleBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    private func uploadLook() {
        guard let data = createLookImageData, !createLookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            createLookError = "Completa todos los campos"
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        do {
            try data.write(to: tempURL)
            let author = Look.Author(name: appModel.user?.name ?? "Usuario", avatarPath: appModel.user?.avatarPath)
            Task {
                let result = await appModel.createLook(
                    title: createLookTitle,
                    coverSourceURL: tempURL,
                    author: author,
                    description: createLookDescription.isEmpty ? nil : createLookDescription
                )
                await MainActor.run {
                    switch result {
                    case .success:
                        resetCreateLook()
                        appModel.refreshLooks()
                    case .failure(let error):
                        createLookError = error.localizedDescription
                    }
                }
            }
        } catch {
            createLookError = error.localizedDescription
        }
    }

    private func resetCreateLook() {
        showCreateLookSheet = false
        createLookTitle = ""
        createLookDescription = ""
        createLookImageData = nil
                createLookError = nil
    }
}

private enum AppDestination: Hashable {
    case product(Product)
    case lookDetail(looks: [Look], start: Look)
    case lookEdit(Look)
    case messages
}

private enum MainTab: String, Hashable, CaseIterable {
    case feed, explore, looks, cart, profile

    var bottomBarItem: BottomBarItem {
        switch self {
        case .feed:
            return BottomBarItem(id: rawValue, title: "Feed", iconKey: "icons/nav/feed/normal.png", selectedIconKey: "icons/nav/feed/selected.png")
        case .explore:
            return BottomBarItem(id: rawValue, title: "Explorar", iconKey: "icons/nav/explore/normal.png", selectedIconKey: "icons/nav/explore/selected.png")
        case .looks:
            return BottomBarItem(id: rawValue, title: "Looks", iconKey: "icons/nav/looks/normal.png", selectedIconKey: "icons/nav/looks/selected.png")
        case .cart:
            return BottomBarItem(id: rawValue, title: "Carrito", iconKey: "icons/nav/cart/normal.png", selectedIconKey: "icons/nav/cart/selected.png")
        case .profile:
            return BottomBarItem(id: rawValue, title: "Perfil", iconKey: "icons/nav/profile/normal.png", selectedIconKey: "icons/nav/profile/selected.png")
        }
    }
}

private struct CreateLookSheet: View {
    @Binding var imageData: Data?
    @Binding var title: String
    @Binding var description: String
    @Binding var errorMessage: String?

    let onUpload: () -> Void
    let onDismiss: () -> Void

    #if os(iOS)
    @State private var photoItem: PhotosPickerItem?
    #endif

    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.m) {
                imagePicker
                inputFields
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Nuevo look")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar", role: .cancel, action: onDismiss)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Subir") { onUpload() }
                        .disabled(!canUpload)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", role: .cancel, action: onDismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Subir") { onUpload() }
                        .disabled(!canUpload)
                }
                #endif
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        .onChange(of: photoItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run { imageData = data }
                }
            }
        }
        #endif
    }

    private var canUpload: Bool {
        imageData != nil && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var imagePicker: some View {
        #if os(iOS)
        PhotosPicker(selection: $photoItem, matching: .images) {
            pickerContent
        }
        .buttonStyle(.plain)
        #else
        Button(action: openPanel) { pickerContent }
        .buttonStyle(.plain)
        #endif
    }

    private var pickerContent: some View {
        ZStack {
            #if canImport(UIKit)
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
            } else {
                placeholder
            }
            #elseif os(macOS)
            if let imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
            } else {
                placeholder
            }
            #else
            placeholder
            #endif
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous)
            .fill(AppTheme.Colors.secondaryBackground)
            .frame(maxWidth: .infinity, minHeight: 200)
            .overlay(
                VStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 24))
                    Text("Añadir foto")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(AppTheme.Colors.secondaryText)
            )
    }

    private var inputFields: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Nombre del look *")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                TextField("Ej. Look urbano minimal", text: $title)
                    .padding()
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Descripción (opcional)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
            }
        }
    }

    #if os(macOS)
    private func openPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
            imageData = data
        }
    }
    #endif
}
