// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ToastView",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "ToastView",
            targets: ["ToastView"]),
    ],
    dependencies: [
        // Any external packages that your library might depend on
    ],
    targets: [
        .target(
            name: "ToastView",
            dependencies: [] // Dependencies related to your ToastView target
        ),
        .testTarget(
            name: "ToastViewTests",
            dependencies: ["ToastView"]
        ),
    ]
)
