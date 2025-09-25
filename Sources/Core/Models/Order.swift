import Foundation

public struct Order: Codable, Identifiable, Equatable, Hashable, Sendable {
    public enum Status: String, Codable, Sendable {
        case processing = "Procesando"
        case shipped = "En reparto"
        case delivered = "Entregado"
    }

    public let id: UUID
    public var productID: String
    public var brand: String
    public var title: String
    public var size: String
    public var status: Status
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        productID: String,
        brand: String,
        title: String,
        size: String,
        status: Status = .processing,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.productID = productID
        self.brand = brand
        self.title = title
        self.size = size
        self.status = status
        self.createdAt = createdAt
    }
}

public extension Order {
    var localizedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
}
