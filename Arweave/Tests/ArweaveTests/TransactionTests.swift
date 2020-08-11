import XCTest
@testable import Arweave

final class TransactionTests: XCTestCase {

    let exampleTxId = "FVUCtTss3ehEVwRf8AlkvBb_wnN3leKw-K7wT5vHfic"

    func testFindTransaction() {
        let expectation = self.expectation(description: "Find transaction with ID")
        var actualTx: Transaction?

        Transaction.find(with: exampleTxId) { result in
            actualTx = try? result.get()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: nil)
        XCTAssertNotNil(actualTx)
    }

    func testFetchDataForTransactionId() {
        let expectation = self.expectation(description: "Fetch transaction data for ID")
        var actualTxData: Base64EncodedString?

        Transaction.data(for: exampleTxId) { result in
            actualTxData = try? result.get()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: nil)
        XCTAssertNotNil(actualTxData)
    }

    func testFetchTransactionStatus_AcceptedTx() throws {
        let expectation = self.expectation(description: "Fetch transaction status for ID")
        var actualTxStatus: Transaction.Status?

        Transaction.status(of: exampleTxId) { result in
            actualTxStatus = try? result.get()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: nil)

        XCTAssertNotNil(actualTxStatus)
        let status = try XCTUnwrap(actualTxStatus)
        if case Transaction.Status.accepted = status {} else {
            XCTFail("Transaction status should be accepted.")
        }
    }

    func testFetchTransactionStatus_InvalidTx() throws {
        let expectation = self.expectation(description: "Fetch transaction status for ID")
        var actualTxStatus: Transaction.Status?

        Transaction.status(of: "invalidId") { result in
            actualTxStatus = try? result.get()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: nil)

        XCTAssertNotNil(actualTxStatus)
        let status = try XCTUnwrap(actualTxStatus)
        if case Transaction.Status.invalid = status {} else {
            XCTFail("Transaction status should be invalid.")
        }
    }

    func testFetchPriceForDataPayload() throws {
        let expectation = self.expectation(description: "Fetch transaction data for ID")
        var cost: Amount?

        let req = Transaction.PriceRequest(bytes: 1200)
        Transaction.price(for: req) { result in
            cost = try? result.get()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: nil)
        let price = try XCTUnwrap(cost)
        XCTAssert(price.value > 0)
    }

    func testCreateNewDataTransaction() {
        let data = "<h1>Hello World!</h1>".data(using: .utf8)!
        let expectedBase64UrlEncodedString = "PGgxPkhlbGxvIFdvcmxkITwvaDE-"

        let transaction = Transaction(data: data)

        XCTAssertEqual(transaction.data, expectedBase64UrlEncodedString)
    }

    func testCreateNewWalletToWalletTransaction() {
        let targetAddress = Address(address: "someOtherWalletAddress")
        let transferAmount = Amount(value: 500, unit: .winston)

        let transaction = Transaction(amount: transferAmount, target: targetAddress)

        XCTAssertEqual(transaction.quantity, "500")
        XCTAssertEqual(transaction.target, "someOtherWalletAddress")
    }

    static var allTests = [
        ("testFindTransaction", testFindTransaction),
        ("testFetchDataForTransactionId", testFetchDataForTransactionId),
        ("testFetchTransactionStatus_AcceptedTx", testFetchTransactionStatus_AcceptedTx),
        ("testFetchTransactionStatus_InvalidTx", testFetchTransactionStatus_InvalidTx),
        ("testFetchPriceForDataPayload", testFetchPriceForDataPayload),
        ("testCreateNewDataTransaction", testCreateNewDataTransaction),
        ("testCreateNewWalletToWalletTransaction", testCreateNewWalletToWalletTransaction),
    ]
}
