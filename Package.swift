// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DLKit",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DLVVM",
            targets: ["DLVVM"]
        ),
        .library(
            name: "FlowLayout",
            targets: ["FlowLayout"]
        ),
        .library(
            name: "SwiftUIKit",
            targets: ["SwiftUIKit"]
        ),
        .library(
            name: "Utils",
            targets: ["Utils"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DLVVM",
            dependencies: [
                "Utils"
            ]
        ),
        .target(
            name: "FlowLayout"
        ),
        .target(
            name: "SwiftUIKit",
            dependencies: [
                "DLVVM",
                "FlowLayout"
            ]
        ),
        .target(
            name: "Utils"
        )
    ]
)
