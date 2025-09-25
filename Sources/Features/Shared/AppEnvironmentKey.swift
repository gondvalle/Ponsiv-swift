import SwiftUI
import Core

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = AppEnvironment(
        productRepository: StubbedRepositories.shared,
        engagementRepository: StubbedRepositories.shared,
        userRepository: StubbedRepositories.shared,
        sessionRepository: StubbedRepositories.shared,
        cartRepository: StubbedRepositories.shared,
        lookRepository: StubbedRepositories.shared,
        orderRepository: StubbedRepositories.shared
    )
}

public extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}

// MARK: - Lightweight fallback to avoid crashes in previews/tests without wiring

private final class StubbedRepositories: ProductRepository,
    EngagementRepository,
    UserRepository,
    SessionRepository,
    CartRepository,
    LookRepository,
    OrderRepository
{
    static let shared = StubbedRepositories()
    private init() {}

    func loadProducts() async throws -> [Product] { [] }
    func likeCounts() async throws -> [String: Int] { [:] }

    func isLiked(productID: String, userID: UUID) async throws -> Bool { false }
    func toggleLike(productID: String, userID: UUID) async throws -> Bool { false }
    func likedIDs(userID: UUID) async throws -> Set<String> { [] }
    func isInWardrobe(productID: String, userID: UUID) async throws -> Bool { false }
    func toggleWardrobe(productID: String, userID: UUID) async throws -> Bool { false }
    func wardrobeIDs(userID: UUID) async throws -> Set<String> { [] }

    func createUser(_ request: CreateUserRequest) async throws -> User { throw AppError.persistenceFailed }
    func authenticate(email: String, password: String) async throws -> User { throw AppError.invalidCredentials }
    func currentUser() async throws -> User? { nil }
    func updateCurrentUser(_ update: (inout User) -> Void) async throws -> User { throw AppError.missingUser }
    func logout() async throws {}
    func setCurrentUser(_ user: User?) async throws {}
    func allUsers() async throws -> [User] { [] }

    func loadSession() async throws -> UUID? { nil }
    func persistSession(id: UUID?) async throws {}

    func loadCart(for userID: UUID) async throws -> CartState { .init() }
    func saveCart(_ cart: CartState, for userID: UUID) async throws {}
    func clearCart(for userID: UUID) async throws {}

    func loadLooks() async throws -> [Look] { [] }
    func save(look: Look) async throws {}
    func update(look: Look) async throws {}
    func delete(lookID: Look.ID) async throws {}

    func loadOrders(for userID: UUID) async throws -> [Order] { [] }
    func save(orders: [Order], for userID: UUID) async throws {}
}
