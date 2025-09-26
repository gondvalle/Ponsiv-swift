import SwiftUI
import Core
import Infrastructure

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
    @State private var showSizeSheet = false

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
        GeometryReader { proxy in
            ZStack {
                imagePager(size: proxy.size)
                overlay(size: proxy.size)
                    .opacity(hideOverlay ? 0 : 1)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color.black)
        }
        .sheet(isPresented: $showSizeSheet) {
            sizeSheet
                .presentationDetents([.medium])
        }
    }

    private func imagePager(size: CGSize) -> some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                RemoteImageView(url: url, contentMode: .fill)
                    .tag(index)
                    .frame(width: size.width, height: size.height)
                    .ignoresSafeArea()
                    .onLongPressGesture(minimumDuration: 0.18) {
                        withAnimation(.easeInOut(duration: 0.2)) { hideOverlay = true }
                    } onPressingChanged: { pressing in
                        if !pressing {
                            withAnimation(.easeInOut(duration: 0.2)) { hideOverlay = false }
                        }
                    }
            }
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #else
        .tabViewStyle(.automatic)
        #endif
    }

    private func overlay(size: CGSize) -> some View {
        ZStack(alignment: .bottomLeading) {
            infoCard
                .padding(.leading, 32)
                .padding(.bottom, 48)

            buttonColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 28)
                .padding(.top, 120)
        }
        .padding(.bottom, 32)
        .padding(.trailing, 24)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(product.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.Colors.primaryText)
                .lineLimit(3)
            Text(product.brand)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.Colors.secondaryText)
            Text(product.displayPrice)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.Colors.primaryText)
        }
        .padding(.vertical, AppTheme.Spacing.m)
        .padding(.horizontal, AppTheme.Spacing.l)
        .frame(minWidth: 220, idealWidth: 260, maxWidth: 280, alignment: .leading)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
        .shadow(color: AppTheme.Colors.primaryText.opacity(0.15), radius: 18, x: 0, y: 8)
        .onTapGesture(perform: callbacks.onOpenDetail)
    }

    private var buttonColumn: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            circleButton(systemName: isLiked ? "heart.fill" : "heart", active: isLiked) {
                HapticsManager.selection()
                callbacks.onLike()
            }
            circleButton(systemName: "square.and.arrow.up") {
                callbacks.onShare()
            }
            circleButton(systemName: "cart") {
                if product.sizes.isEmpty {
                    callbacks.onAddToCart()
                    HapticsManager.success()
                } else {
                    showSizeSheet = true
                }
            }
            circleButton(systemName: isInWardrobe ? "briefcase.fill" : "briefcase", active: isInWardrobe) {
                HapticsManager.selection()
                callbacks.onToggleWardrobe()
            }
        }
    }

    private func circleButton(systemName: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(active ? .white : AppTheme.Colors.primaryText)
                .frame(width: 48, height: 48)
                .background(active ? AppTheme.Colors.primaryText : AppTheme.Colors.surface)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var sizeSheet: some View {
        NavigationView {
            List(product.sizes, id: \.self) { size in
                Button {
                    showSizeSheet = false
                    callbacks.onAddToCart()
                    HapticsManager.success()
                } label: {
                    Text(size)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, AppTheme.Spacing.s)
            }
            .navigationTitle("Elige tu talla")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showSizeSheet = false }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showSizeSheet = false }
                }
                #endif
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}
