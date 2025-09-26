import SwiftUI
import Core
import UIComponents

public struct FeedView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @StateObject private var viewModel = FeedViewModel()

    private let onOpenDetail: (Product) -> Void
    private let launch: FeedLaunch?

    @State private var selection: String = ""
    @State private var shareProduct: Product?

    public init(onOpenDetail: @escaping (Product) -> Void, launch: FeedLaunch? = nil) {
        self.onOpenDetail = onOpenDetail
        self.launch = launch
    }

    public var body: some View {
        GeometryReader { proxy in
            TabView(selection: $selection) {
                ForEach(viewModel.slides) { slide in
                    ProductSlideView(
                        product: slide.product,
                        imageURLs: appModel.productImages(for: slide.product),
                        isLiked: appModel.likedProductIDs.contains(slide.product.id),
                        isInWardrobe: appModel.wardrobeProductIDs.contains(slide.product.id),
                        callbacks: .init(
                            onLike: { appModel.toggleLike(for: slide.product) },
                            onShare: { shareProduct = slide.product },
                            onAddToCart: { appModel.addToCart(productID: slide.product.id) },
                            onToggleWardrobe: { appModel.toggleWardrobe(for: slide.product) },
                            onOpenDetail: { onOpenDetail(slide.product) }
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: proxy.size.height, height: proxy.size.width)
                    .tag(slide.id)
                }
            }
            .rotationEffect(.degrees(90))
            .frame(width: proxy.size.width, height: proxy.size.height)
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            .tabViewStyle(.automatic)
            #endif
            .background(Color.black)
            .ignoresSafeArea()
        }
        .task(id: launch?.id) {
            viewModel.configure(appModel: appModel, launch: launch)
            if let first = viewModel.slides.first?.id {
                selection = first
            }
        }
        .onChange(of: viewModel.slides) { _, slides in
            if slides.contains(where: { $0.id == selection }) == false {
                selection = slides.first?.id ?? ""
            }
        }
        .onChange(of: selection) { _, id in
            guard let index = viewModel.slides.firstIndex(where: { $0.id == id }) else { return }
            viewModel.ensureBuffer(after: index)
            viewModel.trimIfNeeded(currentIndex: index)
        }
        .sheet(item: $shareProduct) { product in
            ShareSheet(items: [product.title, product.displayPrice])
        }
    }
}
