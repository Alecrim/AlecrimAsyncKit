// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "AlecrimAsyncKit",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "AlecrimAsyncKit", targets: ["AlecrimAsyncKit"]),
    ],
    targets: [
        .target(name: "AlecrimAsyncKit", path: "Sources")
    ]
)
