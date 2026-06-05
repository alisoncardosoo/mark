// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Mark",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Mark", targets: ["MarkApp"]),
        .library(name: "MarkCore", targets: ["MarkCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-cmark.git", branch: "gfm")
    ],
    targets: [
        .target(
            name: "MarkCore",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "MarkApp",
            dependencies: ["MarkCore"]
        ),
        .testTarget(
            name: "MarkCoreTests",
            dependencies: ["MarkCore"],
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
