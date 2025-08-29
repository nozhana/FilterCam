// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FilterCamBase",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "FilterCamBase",
            targets: ["FilterCamBase"]),
    ],
    dependencies: [
        .package(path: "../Base/FilterCamCore"),
        .package(path: "../Base/FilterCamMacros"),
        .package(path: "../Base/FilterCamResources"),
        .package(path: "../Base/FilterCamShared"),
        .package(path: "../Base/FilterCamUtilities"),
    ],
    targets: [
        .target(
            name: "FilterCamBase", dependencies: [
                "FilterCamCore",
                "FilterCamMacros",
                "FilterCamResources",
                "FilterCamShared",
                "FilterCamUtilities",
            ]),

    ]
)
