import SwiftUI
import Core
import UIComponents

public struct ProductDetailView: View {
    @EnvironmentObject private var appModel: AppViewModel
    let product: Product

    @State private var shareProduct: Product?

    public init(product: Product) {
        self.product = product
    }

    public var body: some View {
        VStack {
            ProductSlideView(
                product: product,
                imageURLs: appModel.productImages(for: product),
                isLiked: appModel.likedProductIDs.contains(product.id),
                isInWardrobe: appModel.wardrobeProductIDs.contains(product.id),
                callbacks: .init(
                    onLike: { appModel.toggleLike(for: product) },
                    onShare: { shareProduct = product },
                    onAddToCart: { appModel.addToCart(productID: product.id) },
                    onToggleWardrobe: { appModel.toggleWardrobe(for: product) },
                    onOpenDetail: {}
                )
            )
        }
        .navigationTitle(product.brand)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $shareProduct) { product in
            ShareSheet(items: [product.title, product.displayPrice])
        }
    }
}
