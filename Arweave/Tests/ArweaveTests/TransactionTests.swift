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

    static var allTests = [
        ("testFindTransaction", testFindTransaction),
        ("testFetchDataForTransactionId", testFetchDataForTransactionId),
        ("testFetchTransactionStatus_AcceptedTx", testFetchTransactionStatus_AcceptedTx),
        ("testFetchTransactionStatus_InvalidTx", testFetchTransactionStatus_InvalidTx),
    ]
}
