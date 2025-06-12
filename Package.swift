// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "GeneratableModelSystemMacros",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(
            name: "GeneratableModelSystem",
            targets: ["GeneratableModelSystem"]
        ),
        .library(
            name: "GeneratableModelSystemMacros",
            targets: ["GeneratableModelSystemMacros"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "GeneratableModelSystemMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "GeneratableModelSystem"
        ),
        .target(
            name: "GeneratableModelSystemMacros",
            dependencies: ["GeneratableModelSystemMacrosPlugin", "GeneratableModelSystem"]
        ),
        .testTarget(
            name: "GeneratableModelSystemMacrosTests",
            dependencies: [
                "GeneratableModelSystemMacros",
                "GeneratableModelSystem",
            ]
        ),
    ]
)