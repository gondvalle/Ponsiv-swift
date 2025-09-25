import XCTest
@testable import Core
@testable import Infrastructure

final class ProductRepositoryTests: XCTestCase {
    func testLoadProductsFromBundle() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let store = PonsivDataStore(stateDirectory: tempDir)
        let products = try await store.loadProducts()
        XCTAssertGreaterThan(products.count, 0)
        XCTAssertNotNil(products.first(where: { !$0.imagePaths.isEmpty }))
    }

    func testCreateAndAuthenticateUser() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let store = PonsivDataStore(stateDirectory: tempDir)
        let request = CreateUserRequest(email: "test@example.com", password: "secret123", name: "Tester", handle: "tester")
        let user = try await store.createUser(request)
        XCTAssertEqual(user.email, "test@example.com")

        let authenticated = try await store.authenticate(email: "test@example.com", password: "secret123")
        XCTAssertEqual(authenticated.id, user.id)
        let current = try await store.currentUser()
        XCTAssertNotNil(current)
    }
}
