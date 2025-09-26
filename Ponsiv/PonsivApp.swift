import SwiftUI
import PonsivUI

@main
struct PonsivIOSApp: App {
    private let environment: AppEnvironment
    @StateObject private var appModel: AppViewModel

    init() {
        let env = PonsivBootstrap.makeEnvironment()
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
                .ignoresSafeArea()
        }
    }
}
