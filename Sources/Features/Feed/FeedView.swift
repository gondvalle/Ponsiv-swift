import SwiftUI
import Core
import UIComponents

public struct FeedView: View {
    @EnvironmentObject private var appModel: AppViewModel
    let onOpenDetail: (Product) -> Void
    var launch: FeedLaunch?

    @State private var shareProduct: Product?
    @State private var selection: String = ""

    public init(onOpenDetail: @escaping (Product) -> Void, launch: FeedLaunch? = nil) {
        self.onOpenDetail = onOpenDetail
        self.launch = launch
    }

    private var dataSource: [Product] {
        if let launch { return launch.products }
        return appModel.products
    }

    public var body: some View {
        GeometryReader { proxy in
            TabView(selection: $selection) {
                ForEach(dataSource) { product in
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
                            onOpenDetail: { onOpenDetail(product) }
                        )
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: proxy.size.height, height: proxy.size.width)
                    .tag(product.id)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            .tabViewStyle(.automatic)
            #endif
            .rotationEffect(.degrees(-90))
            .frame(width: proxy.size.width, height: proxy.size.height)
            .ignoresSafeArea()
        }
        .background(Color.black)
        .onAppear {
            selection = launch?.startProduct.id ?? dataSource.first?.id ?? selection
        }
        .sheet(item: $shareProduct) { product in
            ShareSheet(items: [product.title, product.displayPrice])
        }
    }
}
