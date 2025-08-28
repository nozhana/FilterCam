// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FilterCamDependencies",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "FilterCamDependencies",
            targets: ["FilterCamDependencies"]),
    ],
    dependencies: [
        .package(path: "../Internal/FilterCamBase"),
        .package(path: "../Internal/FilterCamMacros"),
        .package(path: "../Internal/FilterCamShared"),
    ],
    targets: [
        .target(
            name: "FilterCamDependencies", dependencies: [
                "FilterCamBase",
                "FilterCamMacros",
                "FilterCamShared",
            ]
        ),
    ]
)
