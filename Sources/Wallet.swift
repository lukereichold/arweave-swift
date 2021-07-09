import Foundation
import JOSESwift
import CryptoKit

public struct Wallet: Codable, Hashable, Comparable {
    
    public let key: RSAPrivateKey
    public let keyData: Data
    public var ownerModulus: String
    public var address: Address

    private enum CodingKeys: String, CodingKey {
        case keyData, ownerModulus, address
    }
    
    public static func < (lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.address < rhs.address
    }
    
    public static func == (lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.address == rhs.address
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(keyData)
    }
    
    public init(jwkFileData: Data) throws {
        let jwk = try RSAPrivateKey(data: jwkFileData)
        key = jwk
        keyData = jwkFileData
        ownerModulus = key.modulus
        address = Address(from: key.modulus)
    }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: .keyData)
        try self.init(jwkFileData: data)
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

public struct Address: Hashable, Codable, Equatable, Comparable, CustomStringConvertible {
    
    public let address: String
    public var description: String { address }

    public init(address: String) {
        self.address = address
    }
    
    public static func < (lhs: Address, rhs: Address) -> Bool {
        lhs.address < rhs.address
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
