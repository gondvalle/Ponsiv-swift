import XCTest
@testable import Infrastructure

final class AssetsSnapshotTests: XCTestCase {
    func testAssetIndexIsNotEmpty() {
        XCTAssertFalse(AssetIndex.all.isEmpty, "Asset index generation failed")
    }
}
