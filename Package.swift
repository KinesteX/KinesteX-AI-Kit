// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KinesteXAIKit",
    platforms: [
        .iOS(.v14),      // Supports iOS 13.0 and later
        .macOS(.v11)  // Supports macOS 10.15 and later
    ], products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "KinesteXAIKit",
            targets: ["KinesteXAIKit"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "KinesteXAIKit"),
        .testTarget(
            name: "KinesteXAIKitTests",
            dependencies: ["KinesteXAIKit"]
        ),
    ]
)
