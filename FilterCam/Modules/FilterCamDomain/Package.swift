// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FilterCamDomain",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "FilterCamDomain",
            targets: ["FilterCamDomain"]),
    ],
    dependencies: [
        .package(path: "../Internal/FilterCamInterfaces"),
    ],
    targets: [
        .target(
            name: "FilterCamDomain", dependencies: ["FilterCamInterfaces"]),
    ]
)
