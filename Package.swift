// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Arweave",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Arweave",
            targets: ["Arweave"])
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "14.0.0")),
        .package(url: "https://github.com/lukereichold/JOSESwift.git", .upToNextMajor(from: "2.2.4")),
    ],
    targets: [
        .target(
            name: "Arweave",
            dependencies: ["Moya", "JOSESwift"],
            path: "Sources"),
        .testTarget(
            name: "ArweaveTests",
            dependencies: ["Arweave"],
            path: "Tests")
    ]
)
