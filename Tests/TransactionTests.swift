import XCTest
@testable import Arweave

final class TransactionTests: XCTestCase {

    let exampleTxId = "FVUCtTss3ehEVwRf8AlkvBb_wnN3leKw-K7wT5vHfic"
    static var wallet: Wallet?

    class func initWalletFromKeyfile() {
        let keyPath = Bundle.module.url(forResource: "test-key", withExtension: "json")
        let data = try? Data(contentsOf: keyPath!)
        
        TransactionTests.wallet = try? Wallet(jwkFileData: data!)
        XCTAssertNotNil(TransactionTests.wallet)
    }

    override func setUpWithError() throws {
        super.setUp()
        TransactionTests.initWalletFromKeyfile()
    }

    func testFindTransaction() async {
        let actualTx = try? await Transaction.find(exampleTxId)

        XCTAssertNotNil(actualTx)
    }

    func testFetchDataForTransactionId() async throws {
        let txData = try? await Transaction.data(for: exampleTxId)

        XCTAssertNotNil(txData)
    }

    func testFetchTransactionStatus_AcceptedTx() async throws {
        let txStatus = try await Transaction.status(of: exampleTxId)

        XCTAssertNotNil(txStatus)
        let status = try XCTUnwrap(txStatus)
        if case Transaction.Status.accepted = status {} else {
            XCTFail("Transaction status should be accepted.")
        }
    }

    func testFetchTransactionStatus_InvalidTx() async throws {
        let txStatus = try await Transaction.status(of: "invalidId")

        XCTAssertNotNil(txStatus)
        let status = try XCTUnwrap(txStatus)
        if case Transaction.Status.invalid = status {} else {
            XCTFail("Transaction status should be invalid.")
        }
    }

    func testFetchPriceForDataPayload() async throws {
        // todo: needs updating
//        let req = Transaction.PriceRequest(bytes: 1200)
//        let amount = try await Transaction.price(for: req)
//
//        let price = try XCTUnwrap(amount)
//        XCTAssert(price.value > 0)
    }

    func testCreateNewDataTransaction() async throws {
        let data = "<h1>Hello World!</h1>".data(using: .utf8)!
        let expectedBase64UrlEncodedString = "PGgxPkhlbGxvIFdvcmxkITwvaDE-"
        let wallet = try XCTUnwrap(TransactionTests.wallet)

        let transaction = Transaction(data: data)
        let signedTx = try await transaction.sign(with: wallet)

        XCTAssertEqual(signedTx.data, expectedBase64UrlEncodedString)
    }

    func testCreateNewWalletToWalletTransaction() {
        let targetAddress = Address(address: "someOtherWalletAddress")
        let transferAmount = Amount(value: 500, unit: .winston)

        let transaction = Transaction(amount: transferAmount, target: targetAddress)

        XCTAssertEqual(transaction.quantity, "500")
        XCTAssertEqual(transaction.target, "someOtherWalletAddress")
    }

    func testFetchAnchor() async throws {
        let lastTx = try await Transaction.anchor()
        XCTAssertNotNil(lastTx)
    }

    func testSignTransaction_SetsAnchor() async throws {
        let simpleData = try XCTUnwrap("Arweave".data(using: .utf8))
        let transaction = Transaction(data: simpleData)
        let wallet = try XCTUnwrap(TransactionTests.wallet)

        let lastTx = try await transaction.sign(with: wallet).last_tx
        XCTAssertNotNil(lastTx)
    }

    func testSubmitWalletToWalletTransaction() async throws {
        let targetAddress = Address(address: "QplJv7rsWFH79ianupIhm0HxVggS93GiDpiJFmS86-s")
        let transferAmount = Amount(value: 0.3, unit: .AR)
        let transaction = Transaction(amount: transferAmount, target: targetAddress)

        let wallet = try XCTUnwrap(TransactionTests.wallet)

        let signed = try await transaction.sign(with: wallet)
        XCTAssertEqual(signed.quantity, "300000000000")

        _ = try await signed.commit()
    }

    func testSubmitDataTransaction() async throws {
        let data = "Arweave".data(using: .utf8)!
        let transaction = Transaction(data: data)

        let wallet = try XCTUnwrap(TransactionTests.wallet)
        let signed = try await transaction.sign(with: wallet)

        XCTAssertEqual(signed.quantity, "0")
        XCTAssertEqual(signed.target, "")

        _ = try await signed.commit()
    }

    static var allTests = [
        ("testFindTransaction", testFindTransaction),
        ("testFetchDataForTransactionId", testFetchDataForTransactionId),
        ("testFetchTransactionStatus_AcceptedTx", testFetchTransactionStatus_AcceptedTx),
        ("testFetchTransactionStatus_InvalidTx", testFetchTransactionStatus_InvalidTx),
        ("testFetchPriceForDataPayload", testFetchPriceForDataPayload),
        ("testCreateNewDataTransaction", testCreateNewDataTransaction),
        ("testCreateNewWalletToWalletTransaction", testCreateNewWalletToWalletTransaction),
        ("testFetchAnchor", testFetchAnchor),
        ("testSignTransaction_SetsAnchor", testSignTransaction_SetsAnchor),
        ("testSubmitWalletToWalletTransaction", testSubmitWalletToWalletTransaction),
        ("testSubmitDataTransaction", testSubmitDataTransaction)
    ] as [Any]
}
