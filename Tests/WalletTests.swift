import XCTest
import CryptoKit
@testable import Arweave

final class WalletTests: XCTestCase {

    static let walletAddress = Address(address: "3t2aPa6RArz9ssZ-pEmPiI6rUwAy1v69wm_7Qn0uUt8")
    static var wallet: Wallet?
    
    class func initWalletFromKeyfile() {
        
        let keyPath = Bundle.module.path(forResource: "test-key", ofType: "json")
        guard let keyData = keyPath?.data(using: .utf8) else { return }
        WalletTests.wallet = Wallet(jwkFileData: keyData)
        
        XCTAssertNotNil(WalletTests.wallet)
        XCTAssertEqual(WalletTests.walletAddress, WalletTests.wallet?.address)
    }
    
    override class func setUp() {
        super.setUp()
        WalletTests.initWalletFromKeyfile()
    }
    
    func testCheckWalletBalance() {
        let expectation = self.expectation(description: "Checking wallet balance")
        var balance: Amount?
        
        WalletTests.wallet?.balance { result in
            balance = try? result.get()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
        XCTAssertNotNil(balance?.value)
    }
    
    func testFetchLastTransactionId() {
        let expectation = self.expectation(description: "Fetch last transaction ID for wallet")
        var lastTxId: String?
        
        WalletTests.wallet?.lastTransactionId { result in
            lastTxId = try? result.get()
            expectation.fulfill()
        }
        waitForExpectations(timeout: 20, handler: nil)
        XCTAssertNotNil(lastTxId)
    }

    func testUseCustomClientNode() {
        var actualHost: String?
        var actualScheme: String?
        let expectedScheme = "https"
        let expectedHost = "arweave.net"
        let expectation = self.expectation(description: "HTTP request uses custom host")

        API.host = URL(string: "\(expectedScheme)://\(expectedHost)")
        let target = API(route: .walletBalance(walletAddress: WalletTests.walletAddress))
        HttpClient.request(target) { result in
            let request = try? result.get().request
            actualHost = request?.url?.host
            actualScheme = request?.url?.scheme
            expectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: nil)
        XCTAssertEqual(actualHost, expectedHost)
        XCTAssertEqual(actualScheme, expectedScheme)
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
        ("testUseCustomClientNode", testUseCustomClientNode),
        ("testSignMessage", testSignMessage),
        ("testWinstonToARConversion", testWinstonToARConversion)
    ]
}
