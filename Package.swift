// swift-tools-version: 5.10
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
          name: "TagsField",
          targets: ["TagsField"]
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
    dependencies: [
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DLVVM"
        ),
        .target(
          name: "FlowLayout"
        ),
        .target(
          name: "TagsField",
          dependencies: [
            .Flow,
            .DLVVM
          ]
        ),
        .target(
          name: "SwiftUIKit"
        ),
        .target(
          name: "Utils"
        )
    ]
)

extension Target.Dependency {
  static let DLVVM = Target.Dependency.targetItem(name: "DLVVM", condition: nil)
  static let Flow = Target.Dependency.targetItem(name: "FlowLayout", condition: nil)
}
