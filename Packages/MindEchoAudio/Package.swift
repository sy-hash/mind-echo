// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MindEchoAudio",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "MindEchoAudio", targets: ["MindEchoAudio"]),
    ],
    targets: [
        .target(name: "MindEchoAudio", swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "MindEchoAudioTests", dependencies: ["MindEchoAudio"]),
    ]
)
