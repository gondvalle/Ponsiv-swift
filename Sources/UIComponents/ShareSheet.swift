import SwiftUI

#if canImport(UIKit)
import UIKit

public struct ShareSheet: UIViewControllerRepresentable {
    private let items: [Any]

    public init(items: [Any]) {
        self.items = items
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    public func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#else

public struct ShareSheet: View {
    public init(items: [Any]) {}
    public var body: some View {
        Text("Compartir no disponible en esta plataforma")
    }
}

#endif
