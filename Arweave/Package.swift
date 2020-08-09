// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Arweave",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Arweave",
            targets: ["Arweave"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "14.0.0")),
        .package(url: "https://github.com/airsidemobile/JOSESwift.git", .upToNextMajor(from: "2.2.0")),
    ],
    targets: [
        .target(
            name: "Arweave",
            dependencies: ["Moya", "JOSESwift"]),
        .testTarget(
            name: "ArweaveTests",
            dependencies: ["Arweave"],
            resources: [.process("arweave-keyfile.json")])
    ]
)
