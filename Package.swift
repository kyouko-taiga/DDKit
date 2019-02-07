// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DDKit",
  products: [
    .library(name: "SFDDKit", targets: ["SFDDKit"]),
    .library(name: "MFDDKit", targets: ["MFDDKit"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "SFDDKit", dependencies: ["Homomorphisms", "Utils"]),
    .target(name: "MFDDKit", dependencies: ["Homomorphisms", "Utils"]),
    .target(name: "Homomorphisms", dependencies: ["Utils"]),
    .target(name: "Utils"),

    .testTarget(name: "SFDDTests", dependencies: ["SFDDKit"]),
    .testTarget(name: "MFDDTests", dependencies: ["MFDDKit"]),
    .testTarget(name: "HomomorphismsTests", dependencies: ["Homomorphisms"]),
    .testTarget(name: "UtilsTests", dependencies: ["Utils"]),
  ]
)
