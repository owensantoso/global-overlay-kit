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
        ),
        .library(
            name: "MacDesktopWindowFocusAdapter",
            targets: ["MacDesktopWindowFocusAdapter"]
        )
    ],
    dependencies: [
        .package(path: "../.."),
        .package(path: "../../../DesktopGameCore"),
        .package(
            url: "https://github.com/owensantoso/DesktopSurfaceKit.git",
            exact: "0.2.0-rc.1"
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
                .linkedFramework("AppKit")
            ]
        ),
        .target(
            name: "MacDesktopWindowFocusAdapter",
            dependencies: [
                .product(
                    name: "MacDesktopWindowFocusObservation",
                    package: "DesktopSurfaceKit"
                )
            ]
        ),
        .target(
            name: "DesktopPhysicsKit",
            dependencies: [
                .product(
                    name: "DesktopGameCore",
                    package: "DesktopGameCore"
                ),
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
                .product(
                    name: "DesktopGameCore",
                    package: "DesktopGameCore"
                ),
                "DesktopPhysicsKit",
                "MacDesktopWindowGeometry",
                "MacDesktopWindowFocusAdapter"
            ]
        )
    ]
)
