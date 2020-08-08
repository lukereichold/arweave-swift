import XCTest
@testable import Arweave

final class ArweaveTests: XCTestCase {

    func testInitWalletFromKeyfile() {
        let path = Bundle.module.url(forResource: "arweave-keyfile", withExtension: "json")
        
        guard let keyPath = path else { return }
        
        let data = try? Data(contentsOf: keyPath, options: .alwaysMapped)
        guard let keyData = data else { return }
        
        let wallet = Wallet(jwkFileData: keyData)
        XCTAssertNotNil(wallet)
    }
    
    func testCheckWalletBalance() {
        let expectation = self.expectation(description: "Checking wallet balance")

        let address = Address(address: "3t2aPa6RArz9ssZ-pEmPiI6rUwAy1v69wm_7Qn0uUt8")
        let request = API.walletBalance(walletAddress: address)
        var balance = 0.0
        
        HttpClient.request(target: request) { (response) in
            balance = try! response.map(Double.self)
            expectation.fulfill()
        } error: { error in
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
        XCTAssert(balance > 0)
    }
    
    func testFetchLastTransactionId() {
        let expectation = self.expectation(description: "Fetch last transaction ID for wallet")

        let address = Address(address: "3t2aPa6RArz9ssZ-pEmPiI6rUwAy1v69wm_7Qn0uUt8")
        let request = API.lastTransactionId(walletAddress: address)
        var lastTxId = ""
        
        HttpClient.request(target: request) { (response) in
            lastTxId = try! response.mapString()
            expectation.fulfill()
        } error: { error in
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
        XCTAssertNotEqual(lastTxId, "")
    }

    static var allTests = [
        ("testInitWalletFromKeyfile", testInitWalletFromKeyfile),
        ("testCheckWalletBalance", testCheckWalletBalance),
        ("testFetchLastTransactionId", testFetchLastTransactionId),
    ]
}
