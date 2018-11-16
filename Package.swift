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
        .target(name: "SFDDKit", dependencies: ["Homomorphisms", "WeakSet"]),
        .target(name: "MFDDKit", dependencies: ["Homomorphisms", "WeakSet"]),
        .target(name: "Homomorphisms", dependencies: ["WeakSet"]),
        .target(name: "WeakSet"),

        .testTarget(name: "SFDDTests", dependencies: ["SFDDKit"]),
        .testTarget(name: "MFDDTests", dependencies: ["MFDDKit"]),
        .testTarget(name: "HomomorphismsTests", dependencies: ["Homomorphisms"]),
        .testTarget(name: "WeakSetTests", dependencies: ["WeakSet"]),
    ]
)
