import SwiftUI
import Core

public struct ProductSlideView: View {
    public struct Callbacks {
        public var onLike: () -> Void
        public var onShare: () -> Void
        public var onAddToCart: () -> Void
        public var onToggleWardrobe: () -> Void
        public var onOpenDetail: () -> Void

        public init(
            onLike: @escaping () -> Void,
            onShare: @escaping () -> Void,
            onAddToCart: @escaping () -> Void,
            onToggleWardrobe: @escaping () -> Void,
            onOpenDetail: @escaping () -> Void
        ) {
            self.onLike = onLike
            self.onShare = onShare
            self.onAddToCart = onAddToCart
            self.onToggleWardrobe = onToggleWardrobe
            self.onOpenDetail = onOpenDetail
        }
    }

    private let product: Product
    private let imageURLs: [URL]
    private let isLiked: Bool
    private let isInWardrobe: Bool
    private let callbacks: Callbacks

    @State private var selectedIndex: Int = 0
    @State private var hideOverlay = false

    public init(
        product: Product,
        imageURLs: [URL],
        isLiked: Bool,
        isInWardrobe: Bool,
        callbacks: Callbacks
    ) {
        self.product = product
        self.imageURLs = imageURLs
        self.isLiked = isLiked
        self.isInWardrobe = isInWardrobe
        self.callbacks = callbacks
    }

    public var body: some View {
        ZStack {
            TabView(selection: $selectedIndex) {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                    RemoteImageView(url: url)
                        .tag(index)
                        .onLongPressGesture(minimumDuration: 0.25) {
                            withAnimation { hideOverlay = true }
                        } onPressingChanged: { pressing in
                            if !pressing {
                                withAnimation { hideOverlay = false }
                            }
                        }
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            .tabViewStyle(.automatic)
            #endif

            overlay
                .opacity(hideOverlay ? 0 : 1)
        }
        .background(Color.black)
    }

    @ViewBuilder
    private var overlay: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                    Text(product.brand)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(product.displayPrice)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .onTapGesture(perform: callbacks.onOpenDetail)
                Spacer()
                VStack(spacing: 16) {
                    circleButton(systemName: isLiked ? "heart.fill" : "heart") {
                        callbacks.onLike()
                    }
                    circleButton(systemName: "square.and.arrow.up") {
                        callbacks.onShare()
                    }
                    circleButton(systemName: "cart") {
                        callbacks.onAddToCart()
                    }
                    circleButton(systemName: isInWardrobe ? "briefcase.fill" : "briefcase") {
                        callbacks.onToggleWardrobe()
                    }
                }
            }
            .padding(24)
        }
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(.regularMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
