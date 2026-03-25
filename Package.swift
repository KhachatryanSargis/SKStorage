// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SKStorage",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SKStorage",
            targets: ["SKStorage"]
        )
    ],
    targets: [
        .target(
            name: "SKStorage",
            path: "Sources/SKStorage"
        ),
        .testTarget(
            name: "SKStorageTests",
            dependencies: ["SKStorage"],
            path: "Tests/SKStorageTests"
        )
    ]
)
