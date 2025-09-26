import SwiftUI
import Core
import UIComponents

public struct CartView: View {
    @EnvironmentObject private var appModel: AppViewModel
    let onCheckout: () -> Void

    public init(onCheckout: @escaping () -> Void) {
        self.onCheckout = onCheckout
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            if appModel.cartItems.isEmpty {
                Text("Tu carrito está vacío.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.Colors.surface)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: AppTheme.Spacing.m) {
                        ForEach(appModel.cartItems) { item in
                            cartRow(item)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.l)
                    .padding(.vertical, AppTheme.Spacing.l)
                    .padding(.bottom, 120)
                }
                .background(AppTheme.Colors.surface)
            }

            if !appModel.cartItems.isEmpty {
                bottomBar
                    .background(AppTheme.Colors.surface)
                    .overlay(
                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(height: 1), alignment: .top
                    )
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func cartRow(_ item: AppViewModel.CartItem) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            RemoteImageView(url: appModel.productImages(for: item.product).first, contentMode: .fill, cornerRadius: AppTheme.Radii.s)
                .frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(item.product.title)
                    .font(.system(size: 14, weight: .semibold))
                Text(item.product.brand)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.secondaryText)
                Text(item.product.displayPrice)
                    .font(.system(size: 13, weight: .bold))
            }
            Spacer()
            quantityControls(for: item)
            Button("Eliminar") {
                appModel.removeLine(productID: item.product.id)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(red: 0.82, green: 0.13, blue: 0.13))
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 4)
    }

    private func quantityControls(for item: AppViewModel.CartItem) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            circleButton(label: "−") {
                appModel.removeFromCart(productID: item.product.id, quantity: 1)
            }
            Text("\(item.quantity)")
                .font(.system(size: 14, weight: .medium))
                .frame(minWidth: 20)
            circleButton(label: "＋") {
                appModel.addToCart(productID: item.product.id, quantity: 1)
            }
        }
    }

    private func circleButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.Colors.primaryText)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                Text("Total: \(appModel.cartTotal, format: .currency(code: "EUR"))")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            HStack(spacing: AppTheme.Spacing.m) {
                Button("Vaciar") {
                    appModel.clearCart()
                }
                .buttonStyle(.bordered)

                Button("Realizar pedido") {
                    appModel.placeOrder()
                    onCheckout()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.l)
        .padding(.top, AppTheme.Spacing.m)
        .padding(.bottom, AppTheme.Spacing.l)
    }
}
