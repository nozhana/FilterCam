// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FilterCamCore",
    platforms: [.iOS(.v17), .macOS(.v10_15)],
    products: [
        .library(
            name: "FilterCamCore",
            targets: ["FilterCamCore"]),
    ],
    targets: [
        .target(
            name: "FilterCamCore"),
    ]
)
