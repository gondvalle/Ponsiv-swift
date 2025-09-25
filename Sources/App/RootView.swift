import SwiftUI
import Core
import Features
import Infrastructure
import UIComponents

public struct RootView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var path: [AppDestination] = []
    @State private var selectedTab: MainTab = .feed
    @State private var feedLaunch: FeedLaunch?

    public init() {}

    public var body: some View {
        switch appModel.phase {
        case .loading:
            ProgressView("Cargando…")
                .progressViewStyle(.circular)
        case .failed(let message):
            VStack(spacing: 16) {
                Text("Algo ha ido mal")
                    .font(.title2.bold())
                Text(message)
                    .foregroundStyle(.secondary)
                Button("Reintentar") { appModel.bootstrap() }
            }
            .padding()
        case .needsAuthentication:
            LoginView()
                .environmentObject(appModel)
        case .ready:
            NavigationStack(path: $path) {
                MainTabView(
                    selectedTab: $selectedTab,
                    feedLaunch: $feedLaunch,
                    onOpenProduct: { product in
                        path.append(.product(product))
                    },
                    onOpenFeed: { launch in
                        feedLaunch = launch
                        selectedTab = .feed
                    },
                    onOpenLook: { looks, start in
                        path.append(.lookDetail(looks: looks, start: start))
                    },
                    onEditLook: { look in
                        path.append(.lookEdit(look))
                    },
                    onOpenMessages: {
                        path.append(.messages)
                    }
                )
                .environmentObject(appModel)
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
        }
    }
}

enum AppDestination: Hashable {
    case product(Product)
    case lookDetail(looks: [Look], start: Look)
    case lookEdit(Look)
    case messages
}

enum MainTab: Hashable {
    case feed, explore, looks, cart, profile
}

struct MainTabView: View {
    @Binding var selectedTab: MainTab
    @Binding var feedLaunch: FeedLaunch?

    let onOpenProduct: (Product) -> Void
    let onOpenFeed: (FeedLaunch) -> Void
    let onOpenLook: ([Look], Look) -> Void
    let onEditLook: (Look) -> Void
    let onOpenMessages: () -> Void

    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(onOpenDetail: onOpenProduct, launch: feedLaunch)
                .environmentObject(appModel)
                .tag(MainTab.feed)
                .tabItem { Label("Feed", systemImage: "house") }

            ExploreView(onOpenFeed: { launch in
                onOpenFeed(launch)
            }, onOpenDetail: onOpenProduct)
                .environmentObject(appModel)
                .tag(MainTab.explore)
                .tabItem { Label("Explorar", systemImage: "magnifyingglass") }

            LooksView(onOpenLook: { look in
                onOpenLook(appModel.looks, look)
            }, onEditLook: onEditLook)
                .environmentObject(appModel)
                .tag(MainTab.looks)
                .tabItem { Label("Looks", systemImage: "square.grid.2x2") }

            CartView(onCheckout: {
                selectedTab = .profile
            })
            .environmentObject(appModel)
            .tag(MainTab.cart)
            .tabItem { Label("Carrito", systemImage: "cart") }

            NavigationStack {
                ProfileView()
                    .environmentObject(appModel)
                    #if os(iOS)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: onOpenMessages) {
                                Image(systemName: "bubble.left")
                            }
                        }
                    }
                    #endif
            }
            .tag(MainTab.profile)
            .tabItem { Label("Perfil", systemImage: "person") }
        }
    }
}
