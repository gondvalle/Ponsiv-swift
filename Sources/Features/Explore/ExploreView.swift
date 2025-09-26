import SwiftUI
import Core
import UIComponents

public struct ExploreView: View {
    @EnvironmentObject private var appModel: AppViewModel
    let onOpenFeed: (FeedLaunch) -> Void
    let onOpenDetail: (Product) -> Void

    @State private var query: String = ""

    private let chipLabels = [
        "Todos","Camisas","Zapatillas","Pantalones","Chaquetas","Vestidos","Tops","Camisetas"
    ]

    public init(onOpenFeed: @escaping (FeedLaunch) -> Void, onOpenDetail: @escaping (Product) -> Void) {
        self.onOpenFeed = onOpenFeed
        self.onOpenDetail = onOpenDetail
    }

    private var filteredProducts: [Product] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return appModel.products
        }
        let tokens = query.lowercased().split(separator: " ")
        return appModel.products.filter { product in
            let haystack = "\(product.title) \(product.brand) \(product.category ?? "")".lowercased()
            return tokens.allSatisfy { haystack.contains($0) }
        }
    }

    private var trendingProducts: [Product] {
        filteredProducts.sorted { lhs, rhs in
            let lc = appModel.likeCounts[lhs.id, default: 0]
            let rc = appModel.likeCounts[rhs.id, default: 0]
            if lc == rc {
                return lhs.title < rhs.title
            }
            return lc > rc
        }
    }

    private var categories: [String: [Product]] {
        Dictionary(grouping: filteredProducts) { $0.category ?? "Otros" }
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
                searchField
                banner
                chipsRow
                trendingSection
                categoriesSection
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.vertical, AppTheme.Spacing.l)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
    }

    private var searchField: some View {
        TextField("Buscar marcas, estilos o prendas...", text: $query)
#if os(iOS)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
#endif
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, AppTheme.Spacing.m)
            .background(AppTheme.Colors.secondaryBackground, in: RoundedRectangle(cornerRadius: AppTheme.Radii.l, style: .continuous))
    }

    @ViewBuilder
    private var banner: some View {
        if let bannerURL = appModel.assetURL(for: "banners/verano.png") {
            RemoteImageView(url: bannerURL, contentMode: .fill, cornerRadius: AppTheme.Radii.m)
                .frame(height: 160)
                .onTapGesture { openSummerFeed() }
        }
    }

    private var chipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.s) {
                ForEach(chipLabels, id: \.self) { label in
                    Button {
                        handleChip(label)
                    } label: {
                        Text(label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.vertical, AppTheme.Spacing.s)
                            .background(AppTheme.Colors.secondaryBackground, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, AppTheme.Spacing.s)
        }
    }

    @ViewBuilder
    private var trendingSection: some View {
        if !trendingProducts.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                Text("Tendencias del momento")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.Colors.primaryText)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: AppTheme.Spacing.m) {
                        ForEach(trendingProducts.prefix(15)) { product in
                            trendingCard(product)
                        }
                    }
                }
            }
        }
    }

    private func trendingCard(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            RemoteImageView(url: appModel.productImages(for: product).first, contentMode: .fill, cornerRadius: AppTheme.Radii.m)
                .frame(width: 140, height: 180)
            Text(product.brand)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.secondaryText)
            Text(product.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.Colors.primaryText)
                .lineLimit(1)
            Text(product.displayPrice)
                .font(.system(size: 12, weight: .semibold))
        }
        .frame(width: 140, alignment: .leading)
        .onTapGesture { openTrendingFeed(starting: product) }
    }

    @ViewBuilder
    private var categoriesSection: some View {
        ForEach(categories.keys.sorted(), id: \.self) { key in
            if let products = categories[key] {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    Text(key)
                        .font(.system(size: 16, weight: .bold))
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: AppTheme.Spacing.m) {
                            ForEach(products.prefix(10)) { product in
                                categoryCard(product)
                            }
                        }
                    }
                }
            }
        }
    }

    private func categoryCard(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            RemoteImageView(url: appModel.productImages(for: product).first, contentMode: .fill, cornerRadius: AppTheme.Radii.m)
                .frame(width: 140, height: 180)
            Text(product.title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
        }
        .frame(width: 140, alignment: .leading)
        .onTapGesture { onOpenDetail(product) }
    }

    private func handleChip(_ label: String) {
        if label == "Todos" {
            query = ""
            return
        }
        let keywordMap: [String: [String]] = [
            "Camisas": ["CAMISA"],
            "Zapatillas": ["ZAPATILLA","SNEAKER","NIKE","ADIDAS"],
            "Pantalones": ["PANTALON","PANTALÓN"],
            "Chaquetas": ["CHAQUETA","SOBRECAMISA"],
            "Vestidos": ["VESTIDO"],
            "Tops": ["TOP"],
            "Camisetas": ["CAMISETA"]
        ]
        let keywords = keywordMap[label] ?? []
        if keywords.isEmpty {
            query = label
        } else {
            let filtered = appModel.products.filter { product in
                let upper = product.title.uppercased()
                return keywords.contains(where: { upper.contains($0) })
            }
            if let first = filtered.first {
                openFeed(with: filtered, start: first)
            }
        }
    }

    private func openTrendingFeed(starting product: Product) {
        openFeed(with: trendingProducts, start: product)
    }

    private func openSummerFeed() {
        let summerCategories: Set<String> = ["Vestidos","Camisetas","Tops","Bermudas"]
        let subset = appModel.products.filter { summerCategories.contains($0.category ?? "") }
        if let first = subset.first {
            openFeed(with: subset, start: first)
        }
    }

    private func openFeed(with products: [Product], start: Product) {
        guard !products.isEmpty else { return }
        let launch = FeedLaunch(products: products, startProduct: start)
        onOpenFeed(launch)
    }
}
