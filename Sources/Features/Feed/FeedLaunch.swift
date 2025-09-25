import Foundation
import Core

public struct FeedLaunch: Identifiable, Hashable {
    public let id = UUID()
    public var products: [Product]
    public var startProduct: Product
}
