// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "AlecrimAsyncKit",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .watchOS(.v3),
        .tvOS(.v10)
    ],
    products: [
        .library(name: "AlecrimAsyncKit", targets: ["AlecrimAsyncKit"])
    ],
    targets: [
        .target(name: "AlecrimAsyncKit", path: "Sources")
    ]
)
