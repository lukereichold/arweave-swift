import Foundation
import JOSESwift
import CryptoKit

public struct Wallet {

    let key: RSAPrivateKey
    var address: Address
    
    public init?(jwkFileData: Data) {
        guard let jwk = try? RSAPrivateKey(data: jwkFileData) else { return nil }
        key = jwk
        address = Address(from: key.modulus)
    }
    
    func balance(completion: @escaping (Result<Amount, Error>) -> Void) {
        let target = API(route: .walletBalance(walletAddress: address))
        HttpClient.request(target) { response in
            guard let balance = try? response.map(Double.self) else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            let amount = Amount(value: balance, unit: .winston)
            completion(.success(amount))
        } error: { error in
            completion(.failure(error))
        }
    }
    
    func lastTransactionId(completion: @escaping (Result<TransactionId, Error>) -> Void) {
        let target = API(route: .lastTransactionId(walletAddress: address))
        HttpClient.request(target) { response in
            guard let lastTx = try? response.mapString() else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            completion(.success(lastTx))
        } error: { error in
            completion(.failure(error))
        }
    }
}

struct Address: Equatable {
    let address: String
}

extension Address: CustomStringConvertible {
    init(from modulus: String) {
        guard let data = Data(base64URLEncoded: modulus) else {
            preconditionFailure("Invalid base64 value for JWK public modulus (n) property.")
        }
        let digest = SHA256.hash(data: data)
        address = digest.data.base64URLEncodedString()
    }
    
    var description: String { address }
}

typealias Amount = Measurement<ARUnit>

class ARUnit: Dimension {
    static let AR = ARUnit(symbol: "AR", converter: UnitConverterLinear(coefficient: 1.0))
    static let winston = ARUnit(symbol: "winston", converter: UnitConverterLinear(coefficient: 1e-12))
    static let baseUnit = AR
}
