// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BlogServer",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.63.0"),
    ],
    targets: [
        .executableTarget(
            name: "BlogServer",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ],
            path: "Sources/BlogServer"
        ),
    ]
)
