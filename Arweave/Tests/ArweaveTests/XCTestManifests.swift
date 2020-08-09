import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(WalletTests.allTests),
        testCase(TransactionTests.allTests),
    ]
}
#endif
