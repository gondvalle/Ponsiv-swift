import Foundation
import Core

public struct AssetService: Sendable {
    public init() {}

    public func url(for key: String?) -> URL? {
        guard let key else { return nil }
        if key.hasPrefix("http") || key.hasPrefix("file:") {
            return URL(string: key)
        }
        return AssetLocator.url(for: key)
    }

    public func urls(for keys: [String]) -> [URL] {
        keys.compactMap { AssetLocator.url(for: $0) }
    }

    public func productImageURLs(for product: Product) -> [URL] {
        urls(for: product.imagePaths)
    }

    public func logoURL(for product: Product) -> URL? {
        url(for: product.logoPath)
    }

    public func coverURL(for look: Look) -> URL? {
        url(for: look.coverPath)
    }
}
