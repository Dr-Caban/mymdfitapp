// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MDfit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MDfit",
            targets: ["MDfit"]
        ),
    ],
    targets: [
        .target(
            name: "MDfit",
            path: "Sources/MDfit",
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "MDfitTests",
            dependencies: ["MDfit"],
            path: "Tests"
        ),
    ]
)
