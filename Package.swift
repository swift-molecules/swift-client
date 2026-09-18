// swift-tools-version: 6.4

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-client",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Client",
            targets: ["Client"]
        ),
        .library(name: "Client Macro", targets: ["Client Macro"]),
        .library(name: "Client Macro Core", targets: ["Client Macro Core"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-either.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-atoms/swift-operation.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-interface.git", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "603.0.2"..<"604.0.0"),
    ],
    targets: [
        .target(
            name: "Client",
            dependencies: [
                .product(name: "Either", package: "swift-either")
            ]
        ),
        .testTarget(
            name: "Client Tests",
            dependencies: [
                "Client",
                .product(name: "Either", package: "swift-either"),
            ]
        ),
        .target(
            name: "Client Macro Core",
            dependencies: [
                .product(name: "Interface Macro Core", package: "swift-interface"),
                .product(name: "Product Macro Core", package: "swift-product"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .macro(
            name: "Client Macro Plugin",
            dependencies: [
                "Client Macro Core",
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "Client Macro",
            dependencies: [
                "Client Macro Plugin",
                "Client",
                .product(name: "Either", package: "swift-either"),
                .product(name: "Operation", package: "swift-operation"),
            ]
        ),
        .testTarget(
            name: "Client Macro Tests",
            dependencies: [
                "Client Macro",
                "Client",
                .product(name: "Either", package: "swift-either"),
                .product(name: "Operation", package: "swift-operation"),
                .product(name: "Interface Macro", package: "swift-interface"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
