// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FilterCamBase",
    platforms: [.iOS(.v17), .macOS(.v10_15)],
    products: [
        .library(
            name: "FilterCamBase",
            targets: ["FilterCamBase"]),
    ],
    targets: [
        .target(
            name: "FilterCamBase"),
    ]
)
