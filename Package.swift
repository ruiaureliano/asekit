// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ASEKit",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "ASEKit", targets: ["ASEKit"])
    ],
    targets: [
        .target(name: "ASEKit"),
        .testTarget(name: "ASEKitTests", dependencies: ["ASEKit"])
    ]
)
