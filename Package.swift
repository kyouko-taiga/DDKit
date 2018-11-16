// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DDKit",
    products: [
        .library(name: "SFDD", targets: ["SFDD"]),
        .library(name: "MFDD", targets: ["MFDD"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "SFDD", dependencies: ["Homomorphisms", "WeakSet"]),
        .target(name: "MFDD", dependencies: ["Homomorphisms", "WeakSet"]),
        .target(name: "Homomorphisms", dependencies: ["WeakSet"]),
        .target(name: "WeakSet"),

        .testTarget(name: "SFDDTests", dependencies: ["SFDD"]),
        .testTarget(name: "MFDDTests", dependencies: ["MFDD"]),
        .testTarget(name: "HomomorphismsTests", dependencies: ["Homomorphisms"]),
        .testTarget(name: "WeakSetTests", dependencies: ["WeakSet"]),
    ]
)
