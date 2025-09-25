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
        VStack {
            if appModel.cartItems.isEmpty {
                if #available(macOS 14.0, iOS 17.0, *) {
                    ContentUnavailableView("Tu carrito está vacío", systemImage: "cart")
                } else {
                    Text("Tu carrito está vacío")
                        .foregroundStyle(.secondary)
                }
            } else {
                List(Array(appModel.cartItems.enumerated()), id: \.element.id) { _, item in
                    HStack(spacing: 12) {
                        RemoteImageView(url: appModel.productImages(for: item.product).first, cornerRadius: 12)
                            .frame(width: 72, height: 72)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.product.title)
                                .font(.headline)
                            Text(item.product.brand)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(item.product.displayPrice)
                                .font(.subheadline.weight(.semibold))
                        }
                        Spacer()
                        HStack(spacing: 8) {
                            Button("-") {
                                appModel.removeFromCart(productID: item.product.id, quantity: 1)
                            }
                            .buttonStyle(.bordered)

                            Text("x\(item.quantity)")
                                .font(.subheadline.monospacedDigit())

                            Button("+") {
                                appModel.addToCart(productID: item.product.id, quantity: 1)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    #if os(iOS)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            appModel.removeLine(productID: item.product.id)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                    #endif
                }
                .listStyle(.plain)
                footer
            }
        }
        .navigationTitle("Carrito")
    }

    @ViewBuilder
    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total: \(appModel.cartTotal, format: .currency(code: "EUR"))")
                .font(.title3.weight(.semibold))
            HStack {
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
