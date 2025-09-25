import Foundation

public struct AppEnvironment: Sendable {
    public var productRepository: ProductRepository
    public var engagementRepository: EngagementRepository
    public var userRepository: UserRepository
    public var sessionRepository: SessionRepository
    public var cartRepository: CartRepository
    public var lookRepository: LookRepository
    public var orderRepository: OrderRepository

    public init(
        productRepository: ProductRepository,
        engagementRepository: EngagementRepository,
        userRepository: UserRepository,
        sessionRepository: SessionRepository,
        cartRepository: CartRepository,
        lookRepository: LookRepository,
        orderRepository: OrderRepository
    ) {
        self.productRepository = productRepository
        self.engagementRepository = engagementRepository
        self.userRepository = userRepository
        self.sessionRepository = sessionRepository
        self.cartRepository = cartRepository
        self.lookRepository = lookRepository
        self.orderRepository = orderRepository
    }
}
