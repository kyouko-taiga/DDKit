// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DDKit",
  products: [
    .library(name: "DDKit", targets: ["DDKit"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "DDKit", dependencies: []),
    .testTarget(name: "SFDDTests", dependencies: ["DDKit"]),
    .testTarget(name: "MFDDTests", dependencies: ["DDKit"]),
  ]
)
