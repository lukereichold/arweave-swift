import XCTest
import CryptoKit
@testable import Arweave

final class WalletTests: XCTestCase {

    static let walletAddress = Address(address: "3t2aPa6RArz9ssZ-pEmPiI6rUwAy1v69wm_7Qn0uUt8")
    static var wallet: Wallet?
    
    class func initWalletFromKeyfile() {
        guard let keyData = keyData() else { return }
        
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
        ("testWinstonToARConversion", testWinstonToARConversion),
    ]
}

extension WalletTests {
    class func keyData() -> Data? {
        return """
        {"kty":"RSA","n":"xwjLPzkHiWJEtq4u4jZz3nozw8CpXd7sO9jOwXV94CixFeszUUYuzG1SU_UHqVzwd2uPxgrYZuYCJDxQ7C3XAPni6MQ5RsbK8Txz1qfgw3G5PPpIvglbSdo5K9HBm4pAePs-E3Q5sSugK7KRcZGISsf9bsgJcDifMNAP1FCp4lTq9UdzBMXri99A5dZP5TirGqMvorRuQvZq-9tsCH7VCBT_CZWKNKYPnzP2rLuF09yR1t34VA9gHYNkwPaB2jR3eos6Grr3yH_kcAa0_ol0b8bh_mdKwmBPrgUbeQGqNyORGWp1NBoPoB5rpcRvjvjKvtbKwQ-AcVv9iH3eqy-Z2uG6wcaByRWBXCJvXw9JY509_NNMvutPfDWeQVH_qF_IwSbPqD-6WUnnrfugyVIc5w44F8zEmald7D17rhHbIJ3n00MLQIt9xCVLp0Dgb_Ha3Z1OesDUgWQhYhMgHuB3mPBTQyqDlelotkWNjJA_uF1Up1LHzqpitCtYyPM9NCFK7t3L6YB8l2xo14JY4V1EGuog4kCT4LCetQtkAqbJyJm1sZ6fAzElRIsej7R5K70zxuMohI0hDQ-OF5y9P3jFuPdXfjWFiAa9-Od5sHgS9Zx67gkkPY8gEcfwflVvMz81q-j5JR3G_tCQWYEmRA0Q72vsecg9xXM2wONOQpMpA2k","e":"AQAB","d":"vV1XispmqkZtm-UzRBSMv0JDF96pBV_AINyRMizn2yq7-V-yjoQYqHTmnGyHopKDUwtqWgEdjSEPLoyYbWzbn9kgE1gGKpmeolBi4fsNdMYxeJukM_JRAX33YQKLksHBv5lCoV22OiOIm6qkiInvQz7tl8YIfNXSV63NMbKhP26NsVoOS59HEOgTJdl2YF8_I_PYsZO7SEiM1x0Xtyl849ieIe899AN-33igHA26MS0tMGI2DzwltU66wICIYSQD_PqUCLSUZRWRMSigcYAz4Nk3UUXTMgZSKP5A-iskWJulRKot4qlc7nmi769qeHuq4lEXzQFDshbUrFUdUn_Sf2kJfy_6MD0IU4tcaGn0cdJL_cVGmrkt_eLvK_Puy3m-Bh8UqXkmTQCS6fcrZtSXYgkjedPxLtxwVlLkB4pNUKbks4kALChOKzpsdGFVY961lBxd058T1Lza8lbyr9ZCS8kn1whlNC23HzbzjgOEWuGOth6WwRvPCpB7W3byM9iuXdqGnwSCVBrE0hEW_GKEJB6vNv7PtM5KNOsY8WM1lQj0PlW9aqizV7f4fqh7zAk7D4bY61JCwlDolx6kb2tMA_zi4812aLXklSx2Mvxmp_7wCBmZjPKjk4lCPIauF3SbDe8Cwv_LlC049L64V-PuZ2S6o9Tx07837bFf0oEie1E","p":"6FtG8nHWuLrivKnidzzJ3JM7pHxpdtlNmqc3moIBQciDDvD8BWwcdQtDU7JDm8ewHKmZyZsLBXslrXpYhId1bD6Xnr49KCZhrEm45byuUd3h4n-ang73qCYinFeX2Fuq694Jq9dy0DD5ZbDZWQLDiMqQt06VoeJRiR5HSmME6M6JHnWtWFMIpvLPgLDefmrco_wwDIm6aaQHgP9iWGNCKBHFOnQesdmo_G7TzfwbcCdfJXZf3DAEEqT53Ax721Jm6317LYFxbRtP-pyxHsjUdqaFzuBxQsDn6-F8o3Xp61QIO-bner-bb3qQwO3jl8Cx7hCHV1BCRNYPcSAaFduoNQ","q":"20l_R_N8RT9gDfr54oB0dkTo0EzQLp4NQ3s-olbrGb3H3tSwjDTILINUcrmawPYnXmIV6WY4FQlzr080U-XCr4n-0VZESMGBZvscxXXwPXvESHYznMgb4ngaro3vwDKu4PdOtCOv9sMGzgHvNRO3r19g5NJUP06rGbpkz96k4H4chgHzq8WXNUMzJzbxjxovFXLqDnhSgN9-VR9sYaK3mlOEXLqnk7iR7rNR2v2mlIgZ-NcSsPUnokhhMPYkKSCR34xH3YR3o-PeptTg9M0Nmjd9IYmz6wyRvdmiS-iiIl6DyYMrwSEQqdQdRW-j-YKgqckTPBXUzB0_-P7hzGbc5Q","dp":"gH5Jo7VUet_Ol2qTNEFHmFVLfFDYucK96bJjS2xtaYWLBG470HvS2N8bomNIhBNPzunzg8vbsnJBicfIv7FxPCT5D-5AP73J8c7rExDejaNYUTsjtBiu2CwOo8rEy_8VbE5jpsYEViFfKd88sr6Wh0UN9nDcyqMvV9aIshhEFMJyjYeiDuAMPtaz7YTh5aMO1RiXMbfQgK8W_z07k4mAgkwhd4vTlaK6kq5vLtAmFEWRllP5-vgKqIzXJ9s3ezf8dmnz_lxA74dVGVAhmtaQt_Sqtpbjy3iGSKlvla2VaHAWBZpRlE31lRaAilCDtd34B6DYV26o1wxRicuo4UGRqQ","dq":"j9kbzKg1uftD2Iftyh53x2mWy6XH3vzBOKYtRTL9UEqFRXCCS8cIFOMlz4hfsvsGgkyXkR8D5RDpOXQcoHiVCK_eX5ZWft-pMlPB4Opn6P06mkonu04ttJcS8bScNJlKzLqOf271rErtONBeCZRgp4NKvXAX4duKM_tozE-CGt2_ekzneqPIeCEX-j55oWUMw-Y5EbrubCmv5skRQM8L4AmvR2EOMsIdwNcS-DPyRXcuimUTls-K61LNpt-ggvYhmuKb9f1CuljtosT8uLmWlbaWuBxr0OHS7RZJ97-oNCGKE_OfDTbShoVlmjoM980v9ZC4tG6hxC_f2kfg-UP03Q","qi":"Tzv20yNeaQPYWt3wImklMw1HgZlAcP2hknVEzN2GG-LtEa_rStejw6vEUOaBeUr7wehA78HPG1l5pInIzJtrBzvDqWgu4BwrFFNGZ78ya14yaVMR66xzMXyThqbJ-fVXhqbJT8CbWfUoG7WiE8vvRenl9D65g57do2aUWdDw8dxdosYQ1m519rYfFO97tkGcWFkTJYbL7yBPmLVMfzJDEjpr9D9_UT2fQunyL90LMDnPFXxF4IHrJM8y3NEWq15KSZGsmTIZnrJSUUmNNpE4x59aCwcw4Dmm9n1kL8M7P3zH9D8E2kSdtkX36FvsJNKr8pyZ6sm35CWyt0Lh79XbEw"}
        """.data(using: .utf8)
    }
}
