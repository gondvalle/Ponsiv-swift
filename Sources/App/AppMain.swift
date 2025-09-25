import SwiftUI
import Core
import Infrastructure
import Features

@main
struct PonsivAppMain: App {
    private let dataStore: PonsivDataStore
    private let environment: AppEnvironment

    @StateObject private var appModel: AppViewModel

    init() {
        let store = PonsivDataStore()
        self.dataStore = store
        let env = AppEnvironment(
            productRepository: store,
            engagementRepository: store,
            userRepository: store,
            sessionRepository: store,
            cartRepository: store,
            lookRepository: store,
            orderRepository: store
        )
        self.environment = env
        _appModel = StateObject(wrappedValue: AppViewModel(environment: env))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .environment(\.appEnvironment, environment)
                .task {
                    if appModel.phase == .loading {
                        appModel.bootstrap()
                    }
                }
        }
    }
}
