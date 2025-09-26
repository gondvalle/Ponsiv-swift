import SwiftUI
import UIComponents


public struct MessagesView: View {
    private let messages = [
        (id: UUID(), from: "Ponsiv", text: "¡Bienvenida! Aquí verás tus mensajes."),
        (id: UUID(), from: "Atención al cliente", text: "Tu pedido está en camino 🚚")
    ]

    public init() {}

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(messages, id: \.id) { message in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        Text(message.from)
                            .font(.system(size: 14, weight: .semibold))
                        Text(message.text)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radii.m, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.vertical, AppTheme.Spacing.l)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Mensajes")
    }
}
