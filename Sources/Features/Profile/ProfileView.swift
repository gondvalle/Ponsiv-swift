import SwiftUI
#if os(iOS)
import PhotosUI
#endif
import Core
import UIComponents

public struct ProfileView: View {
    @EnvironmentObject private var appModel: AppViewModel

    @State private var selectedTab: Tab = .looks
    #if os(iOS)
    @State private var pickerItem: PhotosPickerItem?
    #endif

    enum Tab: String, CaseIterable, Identifiable {
        case looks = "Looks"
        case likes = "Likes"
        case wardrobe = "Armario"
        case orders = "Pedidos"

        var id: String { rawValue }
    }

    private var likedProducts: [Product] {
        appModel.products.filter { appModel.likedProductIDs.contains($0.id) }
    }

    private var wardrobeProducts: [Product] {
        appModel.products.filter { appModel.wardrobeProductIDs.contains($0.id) }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                Picker("Sección", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case .looks:
                    looksGrid
                case .likes:
                    productsGrid(likedProducts)
                case .wardrobe:
                    productsGrid(wardrobeProducts)
                case .orders:
                    ordersList
                }
            }
            .padding()
        }
        .navigationTitle("Perfil")
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        #if os(iOS)
        .onChange(of: pickerItem) { newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await appModel.updateAvatar(with: data)
                }
            }
        }
        #endif
    }

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 12) {
            if let avatar = appModel.user?.avatarPath.flatMap({ URL(string: $0) }) ?? appModel.assetURL(for: "logos/Ponsiv.png") {
                RemoteImageView(url: avatar, contentMode: .fill, cornerRadius: 60)
                    .frame(width: 120, height: 120)
            } else {
                Circle()
                    .fill(Color.platformSecondaryBackground)
                    .frame(width: 120, height: 120)
            }

            #if os(iOS)
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("Cambiar foto")
                    .font(.footnote.weight(.semibold))
            }
            #endif

            VStack(spacing: 4) {
                Text(appModel.user?.name ?? "Usuario")
                    .font(.title2.bold())
                Text("@\(appModel.user?.handle ?? "ponsiver")")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                metric(count: appModel.looks.count, label: "Looks")
                metric(count: likedProducts.count, label: "Likes")
                metric(count: wardrobeProducts.count, label: "Armario")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func metric(count: Int, label: String) -> some View {
        VStack {
            Text("\(count)")
                .font(.headline)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var looksGrid: some View {
        if appModel.looks.isEmpty {
            if #available(macOS 14.0, iOS 17.0, *) {
                ContentUnavailableView("Aún no tienes looks", systemImage: "photo")
            } else {
                Text("Aún no tienes looks")
                    .foregroundStyle(.secondary)
            }
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(appModel.looks) { look in
                    VStack(alignment: .leading, spacing: 6) {
                        RemoteImageView(url: appModel.lookCoverURL(look), cornerRadius: 12)
                            .frame(height: 220)
                        Text(look.title)
                            .font(.headline)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func productsGrid(_ products: [Product]) -> some View {
        if products.isEmpty {
            if #available(macOS 14.0, iOS 17.0, *) {
                ContentUnavailableView("Nada por aquí todavía", systemImage: "square.grid.2x2")
            } else {
                Text("Nada por aquí todavía")
                    .foregroundStyle(.secondary)
            }
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(products) { product in
                    VStack(alignment: .leading, spacing: 6) {
                        RemoteImageView(url: appModel.productImages(for: product).first, cornerRadius: 12)
                            .frame(height: 200)
                        Text(product.title)
                            .font(.headline)
                        Text(product.displayPrice)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var ordersList: some View {
        if appModel.orders.isEmpty {
            if #available(macOS 14.0, iOS 17.0, *) {
                ContentUnavailableView("Aún no tienes pedidos", systemImage: "shippingbox")
            } else {
                Text("Aún no tienes pedidos")
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(appModel.orders) { order in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.title)
                            .font(.headline)
                        Text("\(order.brand) · talla \(order.size)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(order.localizedDate)
                            .font(.footnote)
                        Text(order.status.rawValue)
                            .font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}
