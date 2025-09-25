import XCTest
@testable import Core
@testable import Features
@testable import Infrastructure

@MainActor
final class AppViewModelTests: XCTestCase {
    func testBootstrapWithoutSessionRequiresAuth() async {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let store = PonsivDataStore(stateDirectory: tempDir)
        let environment = AppEnvironment(
            productRepository: store,
            engagementRepository: store,
            userRepository: store,
            sessionRepository: store,
            cartRepository: store,
            lookRepository: store,
            orderRepository: store
        )
        let model = AppViewModel(environment: environment)
        model.bootstrap()
        try? await Task.sleep(nanoseconds: 200_000_000)
        if case .needsAuthentication = model.phase {
            // success
        } else {
            XCTFail("Expected needsAuthentication phase")
        }
    }

    func testSignupTransitionsToReady() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let store = PonsivDataStore(stateDirectory: tempDir)
        let environment = AppEnvironment(
            productRepository: store,
            engagementRepository: store,
            userRepository: store,
            sessionRepository: store,
            cartRepository: store,
            lookRepository: store,
            orderRepository: store
        )
        let model = AppViewModel(environment: environment)
        model.bootstrap()
        try? await Task.sleep(nanoseconds: 200_000_000)
        let result = await model.signUp(request: .init(email: "test@demo.es", password: "123456", name: "Test", handle: "test"))
        switch result {
        case .success:
            XCTAssertEqual(model.phase, .ready)
            XCTAssertNotNil(model.user)
        case .failure(let error):
            XCTFail("Signup failed: \(error)")
        }
    }
}
