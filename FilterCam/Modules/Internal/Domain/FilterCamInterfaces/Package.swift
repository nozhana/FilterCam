// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FilterCamInterfaces",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "FilterCamInterfaces",
            targets: ["FilterCamInterfaces"]),
    ],
    dependencies: [
        .package(path: "../../Base/FilterCamShared"),
    ],
    targets: [
        .target(
            name: "FilterCamInterfaces", dependencies: ["FilterCamShared"]),
    ]
)
