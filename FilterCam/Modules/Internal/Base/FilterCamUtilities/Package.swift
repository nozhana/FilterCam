// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FilterCamUtilities",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "FilterCamUtilities",
            targets: ["FilterCamUtilities"]),
    ],
    targets: [
        .target(
            name: "FilterCamUtilities"),
    ]
)
