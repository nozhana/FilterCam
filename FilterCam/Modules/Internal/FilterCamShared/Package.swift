// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FilterCamShared",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "FilterCamShared",
            targets: ["FilterCamShared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/BradLarson/GPUImage3", branch: "main"),
    ],
    targets: [
        .target(
            name: "FilterCamShared",
            dependencies: [.product(name: "GPUImage", package: "gpuimage3")],
            swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiterals")]),
    ]
)
