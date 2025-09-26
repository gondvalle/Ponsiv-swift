import Foundation
import CryptoKit
import Core
import Logging

public actor PonsivDataStore: ProductRepository,
    EngagementRepository,
    UserRepository,
    SessionRepository,
    CartRepository,
    LookRepository,
    OrderRepository
{
    private struct PersistedUser: Codable {
        var id: UUID
        var email: String
        var passwordHash: String
        var name: String
        var handle: String
        var avatarPath: String?
        var age: Int?
        var city: String?
        var sex: String?
        var createdAt: Date

        init(from user: User) {
            self.id = user.id
            self.email = user.email.lowercased()
            self.passwordHash = user.passwordHash
            self.name = user.name
            self.handle = user.handle
            self.avatarPath = user.avatarPath
            self.age = user.age
            self.city = user.city
            self.sex = user.sex
            self.createdAt = user.createdAt
        }

        func toUser() -> User {
            User(
                id: id,
                email: email,
                passwordHash: passwordHash,
                name: name,
                handle: handle,
                avatarPath: avatarPath,
                age: age,
                city: city,
                sex: sex,
                createdAt: createdAt
            )
        }
    }

    private struct PersistedState: Codable {
        var users: [PersistedUser] = []
        var sessionUserID: UUID? = nil
        var carts: [UUID: [String: Int]] = [:]
        var likes: [UUID: Set<String>] = [:]
        var wardrobe: [UUID: Set<String>] = [:]
        var orders: [UUID: [Order]] = [:]
        var looks: [Look] = []
    }

    private let logger: Logger
    private let stateURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var state: PersistedState
    private var cachedProducts: [Product]?

    public init(
        stateDirectory: URL? = nil,
        logger: Logger = Log.core
    ) {
        self.logger = logger
        let fm = FileManager.default
        if let stateDirectory {
            self.stateURL = stateDirectory.appendingPathComponent("ponsiv_state.json", isDirectory: false)
        } else {
            let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
            let dir = base.appendingPathComponent("com.ponsiv.app", isDirectory: true)
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            self.stateURL = dir.appendingPathComponent("state.json", isDirectory: false)
        }

        self.encoder = Self.makeEncoder()
        self.decoder = Self.makeDecoder()
        self.state = (try? Self.loadState(from: stateURL, decoder: decoder)) ?? PersistedState()
        self.cachedProducts = nil
    }

    // MARK: - ProductRepository

    public func loadProducts() async throws -> [Product] {
        if let cachedProducts {
            return cachedProducts
        }
        let products = try Self.decodeProducts()
        cachedProducts = products
        return products
    }

    public func likeCounts() async throws -> [String: Int] {
        try await ensureSessionLoaded()
        var tally: [String: Int] = [:]
        for (_, ids) in state.likes {
            for id in ids {
                tally[id, default: 0] += 1
            }
        }
        return tally
    }

    // MARK: - EngagementRepository

    public func likedIDs(userID: UUID) async throws -> Set<String> {
        state.likes[userID] ?? []
    }

    public func wardrobeIDs(userID: UUID) async throws -> Set<String> {
        state.wardrobe[userID] ?? []
    }

    public func isLiked(productID: String, userID: UUID) async throws -> Bool {
        state.likes[userID]?.contains(productID) ?? false
    }

    public func isInWardrobe(productID: String, userID: UUID) async throws -> Bool {
        state.wardrobe[userID]?.contains(productID) ?? false
    }

    public func toggleLike(productID: String, userID: UUID) async throws -> Bool {
        var set = state.likes[userID] ?? []
        if set.contains(productID) {
            set.remove(productID)
            state.likes[userID] = set
            try persist()
            return false
        } else {
            set.insert(productID)
            state.likes[userID] = set
            try persist()
            return true
        }
    }

    public func toggleWardrobe(productID: String, userID: UUID) async throws -> Bool {
        var set = state.wardrobe[userID] ?? []
        if set.contains(productID) {
            set.remove(productID)
            state.wardrobe[userID] = set
            try persist()
            return false
        } else {
            set.insert(productID)
            state.wardrobe[userID] = set
            try persist()
            return true
        }
    }

    // MARK: - UserRepository

    public func createUser(_ request: CreateUserRequest) async throws -> User {
        if state.users.contains(where: { $0.email == request.email.lowercased() }) {
            throw AppError.emailAlreadyUsed
        }
        let hashed = Self.hashPassword(request.password)
        let user = User(
            email: request.email.lowercased(),
            passwordHash: hashed,
            name: request.name,
            handle: request.handle,
            avatarPath: request.avatarPath,
            age: request.age,
            city: request.city,
            sex: request.sex
        )
        state.users.append(PersistedUser(from: user))
        state.sessionUserID = user.id
        try persist()
        return user
    }

    public func authenticate(email: String, password: String) async throws -> User {
        guard let persisted = state.users.first(where: { $0.email == email.lowercased() }) else {
            throw AppError.invalidCredentials
        }
        let hashed = Self.hashPassword(password)
        guard hashed == persisted.passwordHash else {
            throw AppError.invalidCredentials
        }
        state.sessionUserID = persisted.id
        try persist()
        return persisted.toUser()
    }

    public func currentUser() async throws -> User? {
        guard let id = state.sessionUserID else { return nil }
        return state.users.first(where: { $0.id == id })?.toUser()
    }

    public func updateCurrentUser(_ update: @Sendable (inout User) -> Void) async throws -> User {
        guard let id = state.sessionUserID, let idx = state.users.firstIndex(where: { $0.id == id }) else {
            throw AppError.missingUser
        }
        var user = state.users[idx].toUser()
        update(&user)
        state.users[idx] = PersistedUser(from: user)
        try persist()
        return user
    }

    public func logout() async throws {
        state.sessionUserID = nil
        try persist()
    }

    public func setCurrentUser(_ user: User?) async throws {
        state.sessionUserID = user?.id
        try persist()
    }

    public func allUsers() async throws -> [User] {
        state.users.map { $0.toUser() }
    }

    // MARK: - SessionRepository

    public func loadSession() async throws -> UUID? {
        state.sessionUserID
    }

    public func persistSession(id: UUID?) async throws {
        state.sessionUserID = id
        try persist()
    }

    // MARK: - CartRepository

    public func loadCart(for userID: UUID) async throws -> CartState {
        let quantities = state.carts[userID] ?? [:]
        return CartState(quantities: quantities)
    }

    public func saveCart(_ cart: CartState, for userID: UUID) async throws {
        state.carts[userID] = cart.quantities
        try persist()
    }

    public func clearCart(for userID: UUID) async throws {
        state.carts[userID] = [:]
        try persist()
    }

    // MARK: - OrderRepository

    public func loadOrders(for userID: UUID) async throws -> [Order] {
        state.orders[userID] ?? []
    }

    public func save(orders: [Order], for userID: UUID) async throws {
        state.orders[userID] = orders
        try persist()
    }

    // MARK: - LookRepository

    public func loadLooks() async throws -> [Look] {
        state.looks.sorted(by: { $0.createdAt > $1.createdAt })
    }

    public func save(look: Look) async throws {
        state.looks.append(look)
        try persist()
    }

    public func update(look: Look) async throws {
        guard let idx = state.looks.firstIndex(where: { $0.id == look.id }) else {
            throw AppError.notFound
        }
        state.looks[idx] = look
        try persist()
    }

    public func delete(lookID: Look.ID) async throws {
        state.looks.removeAll { $0.id == lookID }
        try persist()
    }

    // MARK: - Helpers

    private func persist() throws {
        do {
            let data = try encoder.encode(state)
            try data.write(to: stateURL, options: [.atomic])
        } catch {
            logger.error("Failed to persist state: \(error.localizedDescription)")
            throw AppError.persistenceFailed
        }
    }

    private func ensureSessionLoaded() async throws {
        if state.sessionUserID == nil {
            _ = try await currentUser()
        }
    }

    private static func loadState(from url: URL, decoder: JSONDecoder) throws -> PersistedState {
        guard FileManager.default.fileExists(atPath: url.path) else { return PersistedState() }
        let data = try Data(contentsOf: url)
        return try decoder.decode(PersistedState.self, from: data)
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        encoder.dataEncodingStrategy = .base64
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.dataDecodingStrategy = .base64
        return decoder
    }

    private static func hashPassword(_ plain: String) -> String {
        let data = Data(plain.utf8)
        if #available(iOS 13.0, macOS 10.15, *) {
            let digest = SHA256.hash(data: data)
            return digest.map { String(format: "%02x", $0) }.joined()
        } else {
            return data.base64EncodedString()
        }
    }

    private struct ProductInfo: Decodable {
        let nombre: String?
        let marca: String?
        let precio: Double?
        let tallas: [String]?
        let categoria: String?
    }

    private static func decodeProducts() throws -> [Product] {
        guard let assetsBase = AssetLocator.assetsBaseURL() else {
            throw AppError.decodingFailed
        }

        let productosURL = assetsBase.appendingPathComponent("productos")
        let fm = FileManager.default
        guard let brandDirs = try? fm.contentsOfDirectory(
            at: productosURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw AppError.decodingFailed
        }

        let logos = loadLogos(base: assetsBase)
        var products: [Product] = []

        for brandDir in brandDirs {
            let values = try brandDir.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else { continue }
            let brandFolderName = brandDir.lastPathComponent
            let productDirs = try fm.contentsOfDirectory(
                at: brandDir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for productDir in productDirs {
                let productValues = try productDir.resourceValues(forKeys: [.isDirectoryKey])
                guard productValues.isDirectory == true else { continue }
                let stem = productDir.lastPathComponent
                let infoURL = productDir.appendingPathComponent("info.json")
                guard let infoData = try? Data(contentsOf: infoURL) else { continue }

                let decoder = JSONDecoder()
                let info = try decoder.decode(ProductInfo.self, from: infoData)

                let brand = info.marca ?? brandFolderName
                let title = info.nombre ?? stem
                let price = Decimal(info.precio ?? 0)
                let sizes = info.tallas ?? []
                let category = info.categoria

                let imagePaths = imageRelativePaths(for: productDir, base: assetsBase)
                let logoPath = logos[brand] ?? logos[brandFolderName]

                let product = Product(
                    id: stem,
                    brand: brand,
                    title: title,
                    price: price,
                    sizes: sizes,
                    imagePaths: imagePaths,
                    logoPath: logoPath,
                    category: category
                )
                products.append(product)
            }
        }

        return products.sorted { lhs, rhs in
            let brandComparison = lhs.brand.localizedCaseInsensitiveCompare(rhs.brand)
            if brandComparison == .orderedSame {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            return brandComparison == .orderedAscending
        }
    }

    private static func imageRelativePaths(for productDir: URL, base: URL) -> [String] {
        let fm = FileManager.default
        let fotosURL = productDir.appendingPathComponent("fotos")
        guard let files = try? fm.contentsOfDirectory(
            at: fotosURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let sorted = files.sorted { $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending }
        return sorted
            .filter { ["jpg", "jpeg", "png", "webp"].contains($0.pathExtension.lowercased()) }
            .map { $0.path.replacingOccurrences(of: base.path + "/", with: "") }
    }

    private static func loadLogos(base: URL) -> [String: String] {
        let fm = FileManager.default
        let logosURL = base.appendingPathComponent("logos")
        guard let files = try? fm.contentsOfDirectory(
            at: logosURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return [:]
        }

        var map: [String: String] = [:]
        for file in files {
            let stem = file.deletingPathExtension().lastPathComponent
            let relative = file.path.replacingOccurrences(of: base.path + "/", with: "")
            map[stem] = relative
        }
        return map
    }
}
