import Foundation

public protocol ProductRepository: Sendable {
    func loadProducts() async throws -> [Product]
    func likeCounts() async throws -> [String: Int]
}

public protocol EngagementRepository: Sendable {
    func isLiked(productID: String, userID: UUID) async throws -> Bool
    func toggleLike(productID: String, userID: UUID) async throws -> Bool
    func likedIDs(userID: UUID) async throws -> Set<String>
    func isInWardrobe(productID: String, userID: UUID) async throws -> Bool
    func toggleWardrobe(productID: String, userID: UUID) async throws -> Bool
    func wardrobeIDs(userID: UUID) async throws -> Set<String>
}

public protocol UserRepository: Sendable {
    func createUser(_ request: CreateUserRequest) async throws -> User
    func authenticate(email: String, password: String) async throws -> User
    func currentUser() async throws -> User?
    func updateCurrentUser(_ update: @Sendable (inout User) -> Void) async throws -> User
    func logout() async throws
    func setCurrentUser(_ user: User?) async throws
    func allUsers() async throws -> [User]
}

public protocol SessionRepository: Sendable {
    func loadSession() async throws -> UUID?
    func persistSession(id: UUID?) async throws
}

public protocol CartRepository: Sendable {
    func loadCart(for userID: UUID) async throws -> CartState
    func saveCart(_ cart: CartState, for userID: UUID) async throws
    func clearCart(for userID: UUID) async throws
}

public protocol LookRepository: Sendable {
    func loadLooks() async throws -> [Look]
    func save(look: Look) async throws
    func update(look: Look) async throws
    func delete(lookID: Look.ID) async throws
}

public protocol OrderRepository: Sendable {
    func loadOrders(for userID: UUID) async throws -> [Order]
    func save(orders: [Order], for userID: UUID) async throws
}

public struct CreateUserRequest: Sendable {
    public var email: String
    public var password: String
    public var name: String
    public var handle: String
    public var avatarPath: String?
    public var age: Int?
    public var city: String?
    public var sex: String?

    public init(
        email: String,
        password: String,
        name: String,
        handle: String,
        avatarPath: String? = nil,
        age: Int? = nil,
        city: String? = nil,
        sex: String? = nil
    ) {
        self.email = email
        self.password = password
        self.name = name
        self.handle = handle
        self.avatarPath = avatarPath
        self.age = age
        self.city = city
        self.sex = sex
    }
}

public struct CartState: Codable, Sendable, Equatable {
    public var quantities: [String: Int]

    public init(quantities: [String: Int] = [:]) {
        self.quantities = quantities
    }

    public mutating func update(productID: String, delta: Int) {
        let next = (quantities[productID] ?? 0) + delta
        if next <= 0 {
            quantities.removeValue(forKey: productID)
        } else {
            quantities[productID] = next
        }
    }

    public mutating func remove(productID: String) {
        quantities.removeValue(forKey: productID)
    }

    public mutating func clear() {
        quantities.removeAll(keepingCapacity: true)
    }

    public func total(using products: [Product]) -> Decimal {
        var sum = Decimal.zero
        let map = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        for (id, qty) in quantities {
            guard let product = map[id] else { continue }
            let line = product.price * Decimal(qty)
            sum += line
        }
        return sum
    }
}
