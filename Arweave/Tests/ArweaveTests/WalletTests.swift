import XCTest
@testable import Arweave

final class WalletTests: XCTestCase {

    static let walletAddress = Address(address: "3t2aPa6RArz9ssZ-pEmPiI6rUwAy1v69wm_7Qn0uUt8")
    static var wallet: Wallet?
    
    class func initWalletFromKeyfile() {
        let path = Bundle.module.url(forResource: "arweave-keyfile", withExtension: "json")
        
        guard let keyPath = path else { return }
        
        let data = try? Data(contentsOf: keyPath, options: .alwaysMapped)
        guard let keyData = data else { return }
        
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
            switch result {
            case .success(let amount):
                balance = amount
            default: break
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
        XCTAssertNotNil(balance?.value)
    }
    
    func testFetchLastTransactionId() {
        let expectation = self.expectation(description: "Fetch last transaction ID for wallet")
        var lastTxId = ""
        
        WalletTests.wallet?.lastTransactionId { result in
            switch result {
            case .success(let txId):
                lastTxId = txId
            default: break
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 20, handler: nil)
        XCTAssertNotEqual(lastTxId, "")
    }
    
    static var allTests = [
        ("testCheckWalletBalance", testCheckWalletBalance),
        ("testFetchLastTransactionId", testFetchLastTransactionId),
    ]
}
