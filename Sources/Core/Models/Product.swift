import Foundation

public struct Product: Codable, Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public var brand: String
    public var title: String
    public var price: Decimal
    public var sizes: [String]
    public var imagePaths: [String]
    public var logoPath: String?
    public var category: String?

    public init(
        id: String,
        brand: String,
        title: String,
        price: Decimal,
        sizes: [String] = [],
        imagePaths: [String] = [],
        logoPath: String? = nil,
        category: String? = nil
    ) {
        self.id = id
        self.brand = brand
        self.title = title
        self.price = price
        self.sizes = sizes
        self.imagePaths = imagePaths
        self.logoPath = logoPath
        self.category = category
    }
}

public extension Product {
    var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: price as NSDecimalNumber) ?? "€\(price)"
    }
}
