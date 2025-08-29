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
        .package(path: "../Internal/FilterCamCore"),
        .package(path: "../Internal/FilterCamInterfaces"),
        .package(path: "../Internal/FilterCamMacros"),
        .package(path: "../Internal/FilterCamShared"),
        .package(path: "../Internal/FilterCamUtilities"),
    ],
    targets: [
        .target(
            name: "FilterCamDependencies", dependencies: [
                "FilterCamCore",
                "FilterCamInterfaces",
                "FilterCamMacros",
                "FilterCamShared",
                "FilterCamUtilities",
            ]
        ),
    ]
)
