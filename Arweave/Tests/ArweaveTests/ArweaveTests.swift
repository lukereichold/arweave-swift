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

    static var allTests = [
        ("testInitWalletFromKeyfile", testInitWalletFromKeyfile),
    ]
}
