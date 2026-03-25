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
    dependencies: [
        .package(url: "https://github.com/KhachatryanSargis/SKCore.git", branch: "main")
    ],
    targets: [
        .target(
            name: "SKStorage",
            dependencies: ["SKCore"],
            path: "Sources/SKStorage"
        ),
        .testTarget(
            name: "SKStorageTests",
            dependencies: ["SKStorage"],
            path: "Tests/SKStorageTests"
        )
    ]
)
