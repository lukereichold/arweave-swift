# Arweave Client SDK for Swift

![](https://img.shields.io/badge/Swift-5.2-orange.svg)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/lukereichold/arweave-swift/blob/master/LICENSE) 
[![SPM compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Twitter](https://img.shields.io/badge/twitter-@lreichold-blue.svg?style=flat)](https://twitter.com/lreichold)

A lightweight Swift client for the Arweave blockchain

## Installation

To install via [Swift Package Manager](https://swift.org/package-manager), add `Arweave` to your `Package.swift` file. Alternatively, [add it to your Xcode project directly](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/lukereichold/arweave-swift.git", from: "1.0.0")
    ],
    ...
)
```

Then import `Arweave` wherever you’d like to use it:

```swift
import Arweave
```

## Demo

See the included demo app, which dynamically creates a `Wallet` object from an existing Arweave JWK keyfile and uses an [iOS share extension](https://developer.apple.com/design/human-interface-guidelines/ios/extensions/sharing-and-actions/) to create and submit a new data transaction containing the data of a given page in Safari.

![](demo.gif)


## Usage



## Contribute

Contributions welcome. Please check out [the issues](https://github.com/lukereichold/arweave-swift/issues).
