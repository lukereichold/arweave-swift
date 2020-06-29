import Foundation
import JOSESwift
import CryptoKit

public struct Wallet {

    let key: RSAPrivateKey
    var address: Address
    
    public init?(jwkFileData: Data) {
        guard let jwk_private = try? RSAPrivateKey(data: jwkFileData) else { return nil }
        key = jwk_private
        address = Address(from: key.modulus)
    }
}

struct Address {
    let address: String
    
    init(from modulus: String) {
        let data = Data(base64URLEncoded: modulus)!
        let digest = SHA256.hash(data: data)
        address = digest.data.base64URLEncodedString()
    }
}





// AMOUNT STUFF:

typealias Amount = Measurement<ARUnit>

class ARUnit: Dimension {

    static let AR = ARUnit(symbol: "AR", converter: UnitConverterLinear(coefficient: 1.0))
    
    // guaranteed to be an Int:
    static let winston = ARUnit(symbol: "winston", converter: UnitConverterLinear(coefficient: 1e-12))

    static let baseUnit = AR
}

