import SwiftUI

public struct MessagesView: View {
    private let messages = [
        (id: UUID(), from: "Ponsiv", body: "¡Bienvenida! Aquí verás tus mensajes."),
        (id: UUID(), from: "Atención al cliente", body: "Tu pedido está en camino 🚚")
    ]

    public init() {}

    public var body: some View {
        List(messages, id: \.id) { message in
            VStack(alignment: .leading, spacing: 4) {
                Text(message.from)
                    .font(.headline)
                Text(message.body)
                    .font(.subheadline)
            }
            .padding(.vertical, 6)
        }
        .listStyle(.plain)
        .navigationTitle("Mensajes")
    }
}
