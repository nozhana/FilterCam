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
        .package(path: "../FilterCamDomain"),
        .package(path: "../Internal/FilterCamCore"),
        .package(path: "../Internal/FilterCamMacros"),
        .package(path: "../Internal/FilterCamResources"),
        .package(path: "../Internal/FilterCamShared"),
        .package(path: "../Internal/FilterCamUtilities"),
    ],
    targets: [
        .target(
            name: "FilterCamModule", dependencies: [
                "FilterCamDomain",
                "FilterCamCore",
                "FilterCamMacros",
                "FilterCamResources",
                "FilterCamShared",
                "FilterCamUtilities",
            ]
        ),
    ]
)
