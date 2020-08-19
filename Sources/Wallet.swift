import Foundation
import JOSESwift
import CryptoKit

public struct Wallet {

    public let key: RSAPrivateKey
    public var ownerModulus: String
    public var address: Address

    public init?(jwkFileData: Data) {
        guard let jwk = try? RSAPrivateKey(data: jwkFileData) else { return nil }
        key = jwk
        ownerModulus = key.modulus
        address = Address(from: key.modulus)
    }
    
    public func balance(completion: @escaping (Result<Amount, Error>) -> Void) {
        let target = API(route: .walletBalance(walletAddress: address))
        HttpClient.request(target) { result in
            guard let balance = try? result.get().map(Double.self) else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            let amount = Amount(value: balance, unit: .winston)
            completion(.success(amount))
        }
    }
    
    public func lastTransactionId(completion: @escaping (Result<TransactionId, Error>) -> Void) {
        let target = API(route: .lastTransactionId(walletAddress: address))
        HttpClient.request(target) { result in
            guard let lastTx = try? result.get().mapString() else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            completion(.success(lastTx))
        }
    }

    public func sign(_ message: Data) throws -> Data {
        let privateKey: SecKey = try key.converted(to: SecKey.self)

        let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePSSSHA256
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey,
                                                    algorithm,
                                                    message as CFData,
                                                    &error) as Data? else {
                                                        throw error!.takeRetainedValue() as Error
        }
        return signature
    }
}

public struct Address: Equatable, CustomStringConvertible {
    public let address: String
    public var description: String { address }
}

extension Address {
    init(from modulus: String) {
        guard let data = Data(base64URLEncoded: modulus) else {
            preconditionFailure("Invalid base64 value for JWK public modulus (n) property.")
        }
        let digest = SHA256.hash(data: data)
        address = digest.data.base64URLEncodedString()
    }
}

public typealias Amount = Measurement<ARUnit>

public final class ARUnit: Dimension {
    static let AR = ARUnit(symbol: "AR", converter: UnitConverterLinear(coefficient: 1e12))
    static let winston = ARUnit(symbol: "winston", converter: UnitConverterLinear(coefficient: 1.0))

    override public class func baseUnit() -> Self {
        return winston as! Self
    }
}

extension Amount {
    var string: String {
        let value = converted(to: .winston).value
        return String(format: "%.f", value)
    }
}
