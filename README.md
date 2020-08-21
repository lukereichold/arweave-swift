# Arweave Client SDK for Swift

![](https://img.shields.io/badge/Swift-5.2-orange.svg)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/lukereichold/arweave-swift/blob/master/LICENSE) 
[![SPM compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Twitter](https://img.shields.io/badge/twitter-@lreichold-blue.svg?style=flat)](https://twitter.com/lreichold)

A lightweight Swift client for the Arweave blockchain, providing type safety for interacting with the Arweave API

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

### Wallets and Keys

#### Creating a Wallet from an existing JWK keyfile

```swift
guard let keyFileData = try? Data(contentsOf: keyFileUrl) else { return }

let wallet = Wallet(jwkFileData: keyFileData)
```

#### Get the wallet address for a private key

```swift
wallet.address
/// 1seRanklLU_1VTGkEk7P0xAwMJfA7owA1JHW5KyZKlY
```

#### Check wallet balance (asynchronous)

All wallet balances are returned using [winston](https://docs.arweave.org/developers/server/http-api#ar-and-winston) units. 
```swift
wallet.balance { result in
    let balance: Amount = try? result.get()
}
```

#### Convert amounts between AR and winston units
```swift
var transferAmount = Amount(value: 1, unit: .AR)
let amtInWinston = transferAmount.converted(to: .winston)
XCTAssertEqual(amtInWinston.value, 1000000000000, accuracy: 0e-12) // ✅

transferAmount = Amount(value: 2, unit: .winston)
let amtInAR = transferAmount.converted(to: .AR)
XCTAssertEqual(amtInAR.value, 0.000000000002, accuracy: 0e-12) // ✅
```

#### Fetch the last transaction ID for a given wallet (asynchronous)

```swift
wallet.lastTransactionId { result in
    let lastTxId: TransactionId = try? result.get()
}
```

### Transactions



## Contribute

Contributions welcome. Please check out [the issues](https://github.com/lukereichold/arweave-swift/issues).
