// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Ponsiv",
    defaultLocalization: "es",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "PonsivUI",
            targets: ["PonsivUI"]
        ),
        .library(
            name: "PonsivCore",
            targets: ["Core"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.6"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4")
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "Logging", package: "swift-log")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "Infrastructure",
            dependencies: [
                "Core",
                .product(name: "Logging", package: "swift-log")
            ],
            resources: [
                .copy("../../assets")
            ]
        ),
        .target(
            name: "UIComponents",
            dependencies: [
                "Core",
                "Infrastructure"
            ]
        ),
        .target(
            name: "Features",
            dependencies: [
                "Core",
                "Infrastructure",
                "UIComponents"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "App",
            dependencies: [
                "Core",
                "Infrastructure",
                "Features",
                "UIComponents"
            ]
        ),
        .target(
            name: "PonsivUI",
            dependencies: [
                "App",
                "Core",
                "Infrastructure",
                "Features",
                "UIComponents"
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core", "Infrastructure"],
            resources: [
                .process("Fixtures")
            ]
        ),
        .testTarget(
            name: "FeatureTests",
            dependencies: ["Features", "Infrastructure", "Core"],
            resources: [
                .process("Fixtures")
            ]
        ),
        .testTarget(
            name: "SnapshotTests",
            dependencies: ["Features", "UIComponents"],
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
