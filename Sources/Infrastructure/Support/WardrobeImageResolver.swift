import Foundation
import Core

public enum WardrobeImageResolver {
    public static func resolveImageURL(for product: Product, assetService: AssetService = AssetService()) -> URL? {
        let prefix = "productos/\(product.brand)/\(product.id)/fotos/"
        let entries = AssetIndex.all
            .filter { $0.key.hasPrefix(prefix) }
            .sorted { $0.key < $1.key }

        if let solo = entries.first(where: { $0.key.range(of: #"_solo\.[A-Za-z0-9]+$"#, options: .regularExpression) != nil }) {
            return assetService.url(for: solo.key)
        }

        if let first = entries.first {
            return assetService.url(for: first.key)
        }

        if let existing = assetService.productImageURLs(for: product).first {
            return existing
        }

        return nil
    }
}
