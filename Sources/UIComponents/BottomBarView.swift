import SwiftUI
import Infrastructure

public struct BottomBarItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let iconKey: String
    public let selectedIconKey: String

    public init(id: String, title: String, iconKey: String, selectedIconKey: String) {
        self.id = id
        self.title = title
        self.iconKey = iconKey
        self.selectedIconKey = selectedIconKey
    }
}

public struct BottomBarView: View {
    public var items: [BottomBarItem]
    public var selectedID: String
    public var cartBadgeValue: Int
    public var onSelect: (BottomBarItem) -> Void

    private let assetService = AssetService()

    public init(
        items: [BottomBarItem],
        selectedID: String,
        cartBadgeValue: Int = 0,
        onSelect: @escaping (BottomBarItem) -> Void
    ) {
        self.items = items
        self.selectedID = selectedID
        self.cartBadgeValue = cartBadgeValue
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    onSelect(item)
                } label: {
                    VStack(spacing: AppTheme.Spacing.xs) {
                        ZStack(alignment: .topTrailing) {
                            RemoteImageView(
                                url: assetService.url(for: selectedID == item.id ? item.selectedIconKey : item.iconKey),
                                contentMode: .fit
                            )
                            .frame(width: 28, height: 28)

                            if item.id == "cart" && cartBadgeValue > 0 {
                                Text(cartBadgeValue > 99 ? "99+" : "\(cartBadgeValue)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.black, in: Capsule())
                                    .offset(x: 8, y: -8)
                            }
                        }

                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.s)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.top, AppTheme.Spacing.s)
        .padding(.bottom, AppTheme.Spacing.s)
        .background(AppTheme.Colors.surface)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1), alignment: .top
        )
    }
}
