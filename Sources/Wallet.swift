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
    
    public func balance() async throws -> Amount {
        let target = API(route: .walletBalance(walletAddress: address))
        let response = try await HttpClient.request(target)
        
        let respString = String(decoding: response.data, as: UTF8.self)
        guard let balance = Double(respString) else {
            throw "Invalid response"
        }
        
        let amount = Amount(value: balance, unit: .winston)
        return amount
    }
    
    public func lastTransactionId() async throws -> TransactionId {
        let target = API(route: .lastTransactionId(walletAddress: address))
        let response = try await HttpClient.request(target)

        let lastTx = String(decoding: response.data, as: UTF8.self)
        return lastTx
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

    public init(address: String) {
        self.address = address
    }
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
