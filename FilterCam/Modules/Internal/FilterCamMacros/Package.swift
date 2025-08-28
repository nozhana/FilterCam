// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "FilterCamMacros",
    platforms: [.macOS(.v10_15), .iOS(.v17), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "FilterCamMacros",
            targets: ["FilterCamMacros"]
        ),
        .executable(
            name: "FilterCamMacrosClient",
            targets: ["FilterCamMacrosClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
        .package(path: "../FilterCamBase"),
    ],
    targets: [
        .macro(
            name: "FilterCamMacrosInternal",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                "FilterCamBase",
            ]
        ),
        
        .target(name: "FilterCamMacros", dependencies: ["FilterCamMacrosInternal"]),
    
        .executableTarget(name: "FilterCamMacrosClient", dependencies: ["FilterCamMacros"]),
        
    ]
)
