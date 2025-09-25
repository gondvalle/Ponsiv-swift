import Foundation
import Combine
import Core
import Infrastructure
import Logging

@MainActor
public final class AppViewModel: ObservableObject {
    public enum Phase: Equatable {
        case loading
        case needsAuthentication
        case ready
        case failed(String)
    }

    private let environment: AppEnvironment
    private let assetService: AssetService
    private let photoStorage: PhotoStorage
    private let logger: Logger

    @Published public private(set) var phase: Phase = .loading
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var user: User?
    @Published public private(set) var looks: [Look] = []
    @Published public private(set) var cart: CartState = .init()
    @Published public private(set) var likedProductIDs: Set<String> = []
    @Published public private(set) var wardrobeProductIDs: Set<String> = []
    @Published public private(set) var orders: [Order] = []
    @Published public private(set) var likeCounts: [String: Int] = [:]

    public struct CartItem: Identifiable {
        public var product: Product
        public var quantity: Int
        public var id: String { product.id }
    }

    public var cartItems: [CartItem] {
        let map = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        return cart.quantities.compactMap { key, qty in
            guard let product = map[key], qty > 0 else { return nil }
            return CartItem(product: product, quantity: qty)
        }.sorted(by: { $0.product.title < $1.product.title })
    }

    public var cartTotal: Decimal {
        cart.total(using: products)
    }

    public init(
        environment: AppEnvironment,
        assetService: AssetService = AssetService(),
        photoStorage: PhotoStorage = PhotoStorage(),
        logger: Logger = Log.core
    ) {
        self.environment = environment
        self.assetService = assetService
        self.photoStorage = photoStorage
        self.logger = logger
    }

    // MARK: - Bootstrap

    public func bootstrap() {
        phase = .loading
        Task {
            do {
                products = try await environment.productRepository.loadProducts()
                likeCounts = try await environment.productRepository.likeCounts()
                let user = try await environment.userRepository.currentUser()
                if let user {
                    try await establishSession(for: user)
                    phase = .ready
                } else {
                    phase = .needsAuthentication
                }
            } catch {
                logger.error("Bootstrap failed: \(error.localizedDescription)")
                phase = .failed(error.localizedDescription)
            }
        }
    }

    private func establishSession(for user: User) async throws {
        self.user = user
        cart = try await environment.cartRepository.loadCart(for: user.id)
        looks = try await environment.lookRepository.loadLooks()
        likedProductIDs = try await environment.engagementRepository.likedIDs(userID: user.id)
        wardrobeProductIDs = try await environment.engagementRepository.wardrobeIDs(userID: user.id)
        orders = try await environment.orderRepository.loadOrders(for: user.id)
        likeCounts = try await environment.productRepository.likeCounts()
        phase = .ready
    }

    // MARK: - Auth

    public func login(email: String, password: String) async -> Result<Void, Error> {
        do {
            let user = try await environment.userRepository.authenticate(email: email, password: password)
            try await establishSession(for: user)
            return .success(())
        } catch {
            logger.warning("Login failed: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    public func signUp(request: CreateUserRequest) async -> Result<Void, Error> {
        do {
            let user = try await environment.userRepository.createUser(request)
            try await establishSession(for: user)
            return .success(())
        } catch {
            logger.warning("Signup failed: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    public func logout() {
        Task {
            do {
                try await environment.userRepository.logout()
                user = nil
                cart = .init()
                likedProductIDs = []
                wardrobeProductIDs = []
                orders = []
                phase = .needsAuthentication
            } catch {
                logger.error("Logout failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Updates

    public func refreshLooks() {
        Task {
            do {
                looks = try await environment.lookRepository.loadLooks()
            } catch {
                logger.error("Failed to refresh looks: \(error.localizedDescription)")
            }
        }
    }

    public func toggleLike(for product: Product) {
        guard let user else { return }
        Task {
            do {
                let liked = try await environment.engagementRepository.toggleLike(productID: product.id, userID: user.id)
                if liked {
                    likedProductIDs.insert(product.id)
                } else {
                    likedProductIDs.remove(product.id)
                }
            } catch {
                logger.error("toggleLike failed: \(error.localizedDescription)")
            }
        }
    }

    public func toggleWardrobe(for product: Product) {
        guard let user else { return }
        Task {
            do {
                let added = try await environment.engagementRepository.toggleWardrobe(productID: product.id, userID: user.id)
                if added {
                    wardrobeProductIDs.insert(product.id)
                } else {
                    wardrobeProductIDs.remove(product.id)
                }
            } catch {
                logger.error("toggleWardrobe failed: \(error.localizedDescription)")
            }
        }
    }

    public func toggleLike(lookID: String) {
        guard let user else { return }
        Task {
            do {
                let liked = try await environment.engagementRepository.toggleLike(productID: lookID, userID: user.id)
                if liked {
                    likedProductIDs.insert(lookID)
                } else {
                    likedProductIDs.remove(lookID)
                }
            } catch {
                logger.error("toggleLike look failed: \(error.localizedDescription)")
            }
        }
    }

    public func addToCart(productID: String, quantity: Int = 1) {
        guard let user else { return }
        cart.update(productID: productID, delta: quantity)
        persistCart(for: user)
    }

    public func removeFromCart(productID: String, quantity: Int = 1) {
        guard let user else { return }
        cart.update(productID: productID, delta: -quantity)
        persistCart(for: user)
    }

    public func removeLine(productID: String) {
        guard let user else { return }
        cart.remove(productID: productID)
        persistCart(for: user)
    }

    public func clearCart() {
        guard let user else { return }
        cart.clear()
        persistCart(for: user)
    }

    private func persistCart(for user: User) {
        let cartSnapshot = cart
        Task {
            do {
                try await environment.cartRepository.saveCart(cartSnapshot, for: user.id)
            } catch {
                logger.error("Failed to persist cart: \(error.localizedDescription)")
            }
        }
    }

    public func placeOrder() {
        guard let user else { return }
        Task {
            do {
                let items = cart.quantities
                guard !items.isEmpty else { return }
                var newOrders: [Order] = []
                for (id, qty) in items {
                    guard let product = products.first(where: { $0.id == id }) else { continue }
                    for _ in 0..<max(qty, 1) {
                       let order = Order(
                           productID: product.id,
                           brand: product.brand,
                           title: product.title,
                           size: product.sizes.first ?? "M",
                            status: .shipped,
                            createdAt: Date()
                        )
                        newOrders.append(order)
                    }
                }
                orders = newOrders
                try await environment.orderRepository.save(orders: newOrders, for: user.id)
                clearCart()
            } catch {
                logger.error("Failed to place order: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Looks

    public func createLook(title: String, coverSourceURL: URL, author: Look.Author, description: String?) async -> Result<Look, Error> {
        guard let user else { return .failure(AppError.missingUser) }
        do {
            let stored = try photoStorage.persistTemporaryImage(from: coverSourceURL, preferredName: title)
            let look = Look(
                id: "look_\(UUID().uuidString)",
                title: title,
                author: author,
                productIDs: [],
                coverPath: stored,
                description: description,
                createdAt: Date()
            )
            try await environment.lookRepository.save(look: look)
            looks.insert(look, at: 0)
            likedProductIDs = try await environment.engagementRepository.likedIDs(userID: user.id)
            return .success(look)
        } catch {
            logger.error("createLook failed: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    public func updateLook(_ look: Look) {
        Task {
            do {
                try await environment.lookRepository.update(look: look)
                if let idx = looks.firstIndex(where: { $0.id == look.id }) {
                    looks[idx] = look
                }
            } catch {
                logger.error("updateLook failed: \(error.localizedDescription)")
            }
        }
    }

    public func deleteLook(id: Look.ID) {
        Task {
            do {
                try await environment.lookRepository.delete(lookID: id)
                looks.removeAll { $0.id == id }
            } catch {
                logger.error("deleteLook failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers exposed to UI

    public func assetURL(for key: String?) -> URL? {
        assetService.url(for: key)
    }

    public func productImages(for product: Product) -> [URL] {
        assetService.productImageURLs(for: product)
    }

    public func productLogo(for product: Product) -> URL? {
        assetService.logoURL(for: product)
    }

    public func lookCoverURL(_ look: Look) -> URL? {
        assetService.coverURL(for: look)
    }

    public func updateAvatar(with data: Data) async {
        guard let user else { return }
        do {
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            try data.write(to: tmpURL)
            let stored = try photoStorage.persistTemporaryImage(from: tmpURL, preferredName: "avatar_\(user.id)")
            _ = try await environment.userRepository.updateCurrentUser { current in
                current.avatarPath = stored
            }
            self.user = try await environment.userRepository.currentUser()
        } catch {
            logger.error("updateAvatar failed: \(error.localizedDescription)")
        }
    }
}
