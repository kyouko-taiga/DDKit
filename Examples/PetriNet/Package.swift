// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PetriNet",
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/kyouko-taiga/DDKit.git", .branch("dev")),
    .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "4.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(name: "PetriNet", dependencies: ["SFDDKit", "Kanna"]),
  ]
)
