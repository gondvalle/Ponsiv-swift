import SwiftUI
import Core
import UIComponents

public struct ExploreView: View {
    @EnvironmentObject private var appModel: AppViewModel
    let onOpenFeed: (FeedLaunch) -> Void
    let onOpenDetail: (Product) -> Void

    @State private var query: String = ""

    public init(onOpenFeed: @escaping (FeedLaunch) -> Void, onOpenDetail: @escaping (Product) -> Void) {
        self.onOpenFeed = onOpenFeed
        self.onOpenDetail = onOpenDetail
    }

    private var filteredProducts: [Product] {
        guard !query.isEmpty else { return appModel.products }
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
        Dictionary(grouping: filteredProducts) { product in
            product.category ?? "Otros"
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                searchField
                banner
                chipsRow
                trendingSection
                categoriesSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Explorar")
        .background(Color.platformBackground)
    }

    @ViewBuilder
    private var searchField: some View {
        TextField("Buscar marcas, estilos o prendas...", text: $query)
#if os(iOS)
            .textInputAutocapitalization(.never)
#endif
            .padding(12)
            .background(Color.platformSecondaryBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var banner: some View {
        if let bannerURL = appModel.assetURL(for: "banners/verano.png") {
            RemoteImageView(url: bannerURL)
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .onTapGesture {
                    if let first = filteredProducts.first ?? appModel.products.first {
                        let launch = FeedLaunch(products: filteredProducts.isEmpty ? appModel.products : filteredProducts, startProduct: first)
                        onOpenFeed(launch)
                    }
                }
        }
    }

    @ViewBuilder
    private var chipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chipLabels, id: \.self) { label in
                    Button {
                        query = label == "Todos" ? "" : label
                    } label: {
                        Text(label)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.platformSecondaryBackground, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var trendingSection: some View {
        if !trendingProducts.isEmpty {
            Text("Tendencias del momento")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(trendingProducts.prefix(15)) { product in
                        VStack(alignment: .leading, spacing: 8) {
                            RemoteImageView(url: appModel.productImages(for: product).first, cornerRadius: 12)
                                .frame(width: 140, height: 180)
                            Text(product.brand)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text(product.title)
                                .font(.footnote.weight(.semibold))
                                .lineLimit(1)
                            Text(product.displayPrice)
                                .font(.footnote)
                        }
                        .frame(width: 140)
                        .onTapGesture {
                            onOpenFeed(FeedLaunch(products: trendingProducts, startProduct: product))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var categoriesSection: some View {
        ForEach(categories.keys.sorted(), id: \.self) { key in
            if let products = categories[key] {
                Text(key)
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(products.prefix(10)) { product in
                            VStack(alignment: .leading, spacing: 8) {
                                RemoteImageView(url: appModel.productImages(for: product).first, cornerRadius: 12)
                                    .frame(width: 140, height: 180)
                                Text(product.title)
                                    .font(.footnote.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .frame(width: 140)
                            .onTapGesture {
                                onOpenDetail(product)
                            }
                        }
                    }
                }
            }
        }
    }

    private var chipLabels: [String] {
        var labels = ["Todos"]
        labels.append(contentsOf: Array(categories.keys.sorted().prefix(8)))
        return labels
    }
}
