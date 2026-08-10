// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DesktopPhysicsKit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "DesktopPhysicsKit",
            targets: ["DesktopPhysicsKit"]
        ),
        .library(
            name: "MacDesktopWindowGeometry",
            targets: ["MacDesktopWindowGeometry"]
        )
    ],
    dependencies: [
        .package(path: "../.."),
        .package(
            url: "https://github.com/owensantoso/DesktopSurfaceKit.git",
            exact: "0.1.0-rc.3"
        )
    ],
    targets: [
        .target(
            name: "MacDesktopWindowGeometry",
            dependencies: [
                .product(
                    name: "MacDesktopWindowObservation",
                    package: "DesktopSurfaceKit"
                ),
                .product(
                    name: "DesktopGeometry",
                    package: "DesktopSurfaceKit"
                )
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices")
            ]
        ),
        .target(
            name: "DesktopPhysicsKit",
            dependencies: [
                .product(
                    name: "GlobalOverlayKit",
                    package: "GlobalOverlayKit"
                ),
                "MacDesktopWindowGeometry"
            ],
            resources: [
                .copy("Resources/StickFigureCC0")
            ]
        ),
        .testTarget(
            name: "DesktopPhysicsKitTests",
            dependencies: [
                "DesktopPhysicsKit",
                "MacDesktopWindowGeometry"
            ]
        )
    ]
)
