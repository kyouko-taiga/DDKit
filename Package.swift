// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DDKit",
    products: [
        .library(name: "YDD" , targets: ["YDD"]),
        .library(name: "MFDD", targets: ["MFDD"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "YDD",
            dependencies: ["Hashing", "Homomorphisms", "WeakSet"]),
        .target(
            name: "MFDD",
            dependencies: ["Hashing", "Homomorphisms", "WeakSet"]),
        .target(
            name: "Homomorphisms",
            dependencies: ["Hashing", "WeakSet"]),
        .target(name: "Hashing"),
        .target(name: "WeakSet"),

        .testTarget(
            name: "YDDTests",
            dependencies: ["Homomorphisms", "YDD"]),
        .testTarget(
            name: "MFDDTests",
            dependencies: ["Homomorphisms", "MFDD"]),
        .testTarget(
            name: "HomomorphismsTests",
            dependencies: ["Homomorphisms"]),
        .testTarget(
            name: "WeakSetTests",
            dependencies: ["WeakSet"]),
    ]
)
