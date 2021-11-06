import XCTest
import CryptoKit
@testable import Arweave

final class WalletTests: XCTestCase {

    static let walletAddress = Address(address: "3t2aPa6RArz9ssZ-pEmPiI6rUwAy1v69wm_7Qn0uUt8")
    static var wallet: Wallet?
    
    class func initWalletFromKeyfile() {
        
        guard let keyPath = Bundle.module.url(forResource: "test-key", withExtension: "json"),
              let keyData = try? Data(contentsOf: keyPath)
        else { return }
        
        WalletTests.wallet = try? Wallet(jwkFileData: keyData)
        
        XCTAssertNotNil(WalletTests.wallet)
        XCTAssertEqual(WalletTests.walletAddress, WalletTests.wallet?.address)
    }
    
    override class func setUp() {
        super.setUp()
        WalletTests.initWalletFromKeyfile()
    }
    
    func testCheckWalletBalance() async throws {
        let balance = try await WalletTests.wallet?.balance()
        XCTAssertNotNil(balance?.value)
    }
    
    func testCheckWalletBalance_UsingCustomHost() async throws {
        API.baseUrl = URL(string: "https://arweave.net:443")!
        let balance = try await WalletTests.wallet?.balance()
        XCTAssertNotNil(balance?.value)
    }

    func testFetchLastTransactionId() async throws {
        let lastTxId = try await WalletTests.wallet?.lastTransactionId()
        XCTAssertNotNil(lastTxId)
    }

    func testSignMessage() throws {
        let msg = try XCTUnwrap("Arweave".data(using: .utf8))
        let wallet = try XCTUnwrap(WalletTests.wallet)
        let signedData = try wallet.sign(msg)

        let hash = SHA256.hash(data: signedData).data.base64URLEncodedString()
        XCTAssertNotNil(hash)
    }

    func testWinstonToARConversion() {
        var transferAmount = Amount(value: 1, unit: .AR)
        let amtInWinston = transferAmount.converted(to: .winston)
        XCTAssertEqual(amtInWinston.value, 1000000000000, accuracy: 0e-12)

        transferAmount = Amount(value: 2, unit: .winston)
        let amtInAR = transferAmount.converted(to: .AR)
        XCTAssertEqual(amtInAR.value, 0.000000000002, accuracy: 0e-12)
    }

    static var allTests = [
        ("testCheckWalletBalance", testCheckWalletBalance),
        ("testFetchLastTransactionId", testFetchLastTransactionId),
        ("testSignMessage", testSignMessage),
        ("testWinstonToARConversion", testWinstonToARConversion)
    ]
}
