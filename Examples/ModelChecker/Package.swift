// swift-tools-version:5.1
import PackageDescription

let package = Package(
  name: "mc",
  products: [
    .executable(name: "mc", targets: ["mc"]),
  ],
  dependencies: [
    .package(path: "../../"),
  ],
  targets: [
    // The Anzen compiler CLI.
    .target(name: "mc", dependencies: ["DDKit"]),
  ]
)
