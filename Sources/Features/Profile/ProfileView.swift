import SwiftUI
#if os(iOS)
import PhotosUI
#endif
import Core
import UIComponents
import Infrastructure

public struct ProfileView: View {
    @EnvironmentObject private var appModel: AppViewModel

    @State private var selectedTab: Tab = .looks
    #if os(iOS)
    @State private var photoItem: PhotosPickerItem?
    #endif
    @State private var isUpdatingAvatar = false

    private let assetService = AssetService()
    private let gridColumns = [GridItem(.flexible(), spacing: AppTheme.Spacing.m), GridItem(.flexible(), spacing: AppTheme.Spacing.m)]

    enum Tab: String, CaseIterable, Identifiable {
        case looks = "Looks"
        case likes = "Likes"
        case wardrobe = "Armario"
        case orders = "Pedidos"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .looks: return "square.grid.2x2"
            case .likes: return "heart"
            case .wardrobe: return "briefcase"
            case .orders: return "reader"
            }
        }
    }

    private var likedProducts: [Product] {
        appModel.products.filter { appModel.likedProductIDs.contains($0.id) }
    }

    private var wardrobeProducts: [Product] {
        appModel.products.filter { appModel.wardrobeProductIDs.contains($0.id) }
    }

    private let headerHeight: CGFloat = 220

    public init() {}

    public var body: some View {
        CollapsibleHeaderScrollView(
            headerHeight: headerHeight,
            stickyHeight: 60,
            content: { contentSection },
            header: { _, _ in headerSection },
            sticky: { _, _ in stickyTabs }
        )
        #if os(iOS)
        .onChange(of: photoItem) { newValue in
            guard let item = newValue else { return }
            Task { await updateAvatar(from: item) }
        }
        #endif
    }

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            avatarPicker
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(appModel.user?.name ?? "Usuario")
                    .font(.system(size: 20, weight: .bold))
                Text("@\(appModel.user?.handle ?? "ponsiver")")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            HStack(spacing: AppTheme.Spacing.l) {
                metricView(count: appModel.looks.count, label: "Outfits")
                metricView(count: likedProducts.count, label: "Likes")
                metricView(count: wardrobeProducts.count, label: "Armario")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.m)
        .padding(.bottom, AppTheme.Spacing.s)
        .background(AppTheme.Colors.surface)
    }

    private var stickyTabs: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: selectedTab == tab ? "\(tab.icon).fill" : tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .regular))
                    }
                    .foregroundColor(selectedTab == tab ? AppTheme.Colors.primaryText : AppTheme.Colors.primaryText.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.s)
                }
                .buttonStyle(.plain)
            }
        }
        .background(AppTheme.Colors.surface)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1), alignment: .bottom
        )
    }

    @ViewBuilder
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            switch selectedTab {
            case .looks:
                looksGrid
            case .likes:
                productsGrid(products: likedProducts)
            case .wardrobe:
                wardrobeGrid
            case .orders:
                ordersSection
            }
        }
        .padding(.horizontal, AppTheme.Spacing.l)
        .padding(.bottom, AppTheme.Spacing.xl)
        .background(AppTheme.Colors.background)
    }

    private var looksGrid: some View {
        Group {
            if appModel.looks.isEmpty {
                emptyState(text: "Aún no tienes looks.")
            } else {
                LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.m) {
                    ForEach(appModel.looks) { look in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            RemoteImageView(url: appModel.lookCoverURL(look), contentMode: .fill, cornerRadius: AppTheme.Radii.m)
                                .frame(height: 240)
                            Text(look.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.primaryText)
                            Text("Por \(look.author.name)")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                    }
                }
            }
        }
    }

    private var wardrobeGrid: some View {
        Group {
            if wardrobeProducts.isEmpty {
                emptyState(text: "Nada por aquí todavía.")
            } else {
                LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.m) {
                    ForEach(wardrobeProducts) { product in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            RemoteImageView(url: WardrobeImageResolver.resolveImageURL(for: product, assetService: assetService), contentMode: .fill, cornerRadius: AppTheme.Radii.m)
                                .frame(height: 240)
                            Text(product.title)
                                .font(.system(size: 14, weight: .semibold))
                            Text("\(product.brand) · \(product.displayPrice)")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                    }
                }
            }
        }
    }

    private func productsGrid(products: [Product]) -> some View {
        Group {
            if products.isEmpty {
                emptyState(text: "Nada por aquí todavía.")
            } else {
                LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.m) {
                    ForEach(products) { product in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            RemoteImageView(url: appModel.productImages(for: product).first, contentMode: .fill, cornerRadius: AppTheme.Radii.m)
                                .frame(height: 240)
                            Text(product.title)
                                .font(.system(size: 14, weight: .semibold))
                            Text(product.displayPrice)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                    }
                }
            }
        }
    }

    private var ordersSection: some View {
        Group {
            if appModel.orders.isEmpty {
                emptyState(text: "Aún no tienes pedidos.")
            } else {
                VStack(spacing: AppTheme.Spacing.m) {
                    ForEach(appModel.orders) { order in
                        HStack(spacing: AppTheme.Spacing.m) {
                            RemoteImageView(url: imageURL(for: order), contentMode: .fill, cornerRadius: AppTheme.Radii.s)
                                .frame(width: 60, height: 60)
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text(order.title)
                                    .font(.system(size: 14, weight: .semibold))
                                Text("\(order.brand) · Talla \(order.size)")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                                HStack(spacing: AppTheme.Spacing.s) {
                                    Text("Pedido: \(order.localizedDate)")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.Colors.secondaryText)
                                    statusBadge(order.status)
                                }
                            }
                            Spacer()
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func statusBadge(_ status: Order.Status) -> some View {
        let background: Color = status == .delivered ? AppTheme.Colors.successBackground : AppTheme.Colors.warningBackground
        return Text(status.rawValue)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, AppTheme.Spacing.s)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }

    private func metricView(count: Int, label: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
    }

    private func emptyState(text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(AppTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
    }

    private var avatarPicker: some View {
        Group {
            #if os(iOS)
            PhotosPicker(selection: $photoItem, matching: .images) {
                avatarView
            }
            .buttonStyle(.plain)
            #else
            Button(action: selectAvatarMac) {
                avatarView
            }
            .buttonStyle(.plain)
            #endif
        }
    }

    private var avatarView: some View {
        ZStack {
            RemoteImageView(url: avatarURL, contentMode: .fill)
                .frame(width: 110, height: 110)
                .clipShape(Circle())
            if isUpdatingAvatar {
                ProgressView()
            }
        }
    }

    private var avatarURL: URL? {
        if let path = appModel.user?.avatarPath {
            if let url = URL(string: path), url.scheme != nil {
                return url
            }
            return assetService.url(for: path)
        }
        return assetService.url(for: "logos/Ponsiv.png")
    }

    #if os(macOS)
    private func selectAvatarMac() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
            Task { await persistAvatar(data: data) }
        }
    }
    #endif

    #if os(iOS)
    private func updateAvatar(from item: PhotosPickerItem) async {
        isUpdatingAvatar = true
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await persistAvatar(data: data)
            }
        } catch {
            await MainActor.run { isUpdatingAvatar = false }
        }
    }
    #endif

    private func persistAvatar(data: Data) async {
        await appModel.updateAvatar(with: data)
        await MainActor.run { isUpdatingAvatar = false }
    }

    private func imageURL(for order: Order) -> URL? {
        if let product = appModel.products.first(where: { $0.id == order.productID }) {
            return appModel.productImages(for: product).first
        }
        return nil
    }
}
