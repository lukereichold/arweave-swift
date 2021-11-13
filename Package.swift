// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Arweave",
    platforms: [
        .macOS("12.0"),
        .iOS("15.0")
    ],
    products: [
        .library(
            name: "Arweave",
            targets: ["Arweave"])
    ],
    dependencies: [
        .package(url: "https://github.com/lukereichold/JOSESwift.git", .upToNextMajor(from: "2.2.4"))
    ],
    targets: [
        .target(
            name: "Arweave",
            dependencies: ["JOSESwift"],
            path: "Sources"),
        .testTarget(
            name: "ArweaveTests",
            dependencies: ["Arweave"],
            path: "Tests",
            resources: [.process("test-key.json")])
    ]
)
