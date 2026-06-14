// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "MindEchoCore",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "MindEchoCore", targets: ["MindEchoCore"])
    ],
    targets: [
        .target(name: "MindEchoCore"),
        .testTarget(name: "MindEchoCoreTests", dependencies: ["MindEchoCore"]),
    ]
)
