import Foundation
import Core
import Infrastructure
import Features

public enum PonsivBootstrap {
    public static func makeEnvironment(stateDirectory: URL? = nil) -> AppEnvironment {
        let store = PonsivDataStore(stateDirectory: stateDirectory)
        return AppEnvironment(
            productRepository: store,
            engagementRepository: store,
            userRepository: store,
            sessionRepository: store,
            cartRepository: store,
            lookRepository: store,
            orderRepository: store
        )
    }

    @MainActor
    public static func makeAppViewModel(stateDirectory: URL? = nil) -> AppViewModel {
        AppViewModel(environment: makeEnvironment(stateDirectory: stateDirectory))
    }
}
