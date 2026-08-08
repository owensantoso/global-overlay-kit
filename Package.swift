// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GlobalOverlayKit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "GlobalOverlayKit",
            targets: ["GlobalOverlayKit"]
        )
    ],
    targets: [
        .target(name: "GlobalOverlayKit"),
        .testTarget(
            name: "GlobalOverlayKitTests",
            dependencies: ["GlobalOverlayKit"]
        )
    ]
)

