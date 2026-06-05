// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MarkAssistant",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MarkAssistant", targets: ["MarkAssistant"]),
        .library(name: "MarkAssistantCore", targets: ["MarkAssistantCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-cmark.git", branch: "gfm")
    ],
    targets: [
        .target(
            name: "MarkAssistantCore",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "MarkAssistant",
            dependencies: ["MarkAssistantCore"]
        ),
        .testTarget(
            name: "MarkAssistantCoreTests",
            dependencies: ["MarkAssistantCore"],
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
