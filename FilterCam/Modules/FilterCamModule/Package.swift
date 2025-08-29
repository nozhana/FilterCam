// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FilterCamModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "FilterCamModule",
            targets: ["FilterCamModule"]),
    ],
    dependencies: [
        .package(path: "../Internal/FilterCamBase"),
        .package(path: "../Internal/FilterCamDomain"),
    ],
    targets: [
        .target(
            name: "FilterCamModule", dependencies: [
                "FilterCamBase",
                "FilterCamDomain",
            ]
        ),
    ]
)
