import Foundation
import CryptoKit

public typealias TransactionId = String
public typealias Base64EncodedString = String

public extension Transaction {

    struct PriceRequest {
        var bytes: Int = 0
        var target: Address?
    }

    struct Tag: Codable {
        public let name: String
        public let value: String

        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }
}

public struct Transaction: Codable {
    public var id: TransactionId = ""
    public var last_tx: TransactionId = ""
    public var owner: String = ""
    public var tags = [Tag]()
    public var target: String = ""
    public var quantity: String = "0"
    public var data: String = ""
    public var reward: String = ""
    public var signature: String = ""

    private enum CodingKeys: String, CodingKey {
        case id, last_tx, owner, tags, target, quantity, data, reward, signature
    }

    var priceRequest: PriceRequest {
        PriceRequest(bytes: rawData.count, target: Address(address: target))
    }

    public var rawData = Data()
}

public extension Transaction {
    init(data: Data) {
        self.rawData = data
    }

    init(amount: Amount, target: Address) {
        self.quantity = String(describing: amount)
        self.target = target.address
    }

    func sign(with wallet: Wallet) async throws -> Transaction {
        var tx = self
        
        tx.last_tx = try await Transaction.anchor()
        tx.data = rawData.base64URLEncodedString()
        
        let priceAmount = try await Transaction.price(for: priceRequest)
        tx.reward = String(describing: priceAmount)

        tx.owner = wallet.ownerModulus
        let signedMessage = try wallet.sign(tx.signatureBody())
        tx.signature = signedMessage.base64URLEncodedString()
        tx.id = SHA256.hash(data: signedMessage).data
            .base64URLEncodedString()
        return tx
    }

    func commit() async throws {
        guard !signature.isEmpty else {
            throw "Missing signature on transaction."
        }

        let commit = API(route: .commit(self))
        _ = try await HttpClient.request(commit)
    }

    private func signatureBody() -> Data {
        return [
            Data(base64URLEncoded: owner),
            Data(base64URLEncoded: target),
            rawData,
            quantity.data(using: .utf8),
            reward.data(using: .utf8),
            Data(base64URLEncoded: last_tx),
            tags.combined.data(using: .utf8)
        ]
        .compactMap { $0 }
        .combined
    }
}

public extension Transaction {

    typealias Response<T> = (Swift.Result<T, Error>) -> Void
    
    enum VoidResult {
        case success
        case failure(Error)
    }

    static func find(_ txId: TransactionId) async throws -> Transaction {
        let findEndpoint = API(route: .transaction(id: txId))
        let response = try await HttpClient.request(findEndpoint)
        return try JSONDecoder().decode(Transaction.self, from: response.data)
    }

    static func data(for txId: TransactionId) async throws -> Base64EncodedString {
        let target = API(route: .transactionData(id: txId))
        let response = try await HttpClient.request(target)
        return String(decoding: response.data, as: UTF8.self)
    }

    static func status(of txId: TransactionId) async throws -> Transaction.Status {

        let target = API(route: .transactionStatus(id: txId))
        let response = try await HttpClient.request(target)
        
        var status: Transaction.Status
        if response.statusCode == 200 {
            let data = try JSONDecoder().decode(Transaction.Status.Data.self, from: response.data)
            status = .accepted(data: data)
        } else {
            status = Transaction.Status(rawValue: .status(response.statusCode))!
        }
        return status
    }

    static func price(for request: Transaction.PriceRequest) async throws -> Amount {
        let target = API(route: .reward(request))
        let response = try await HttpClient.request(target)

        let costString = String(decoding: response.data, as: UTF8.self)
        guard let value = Double(costString) else {
            throw "Invalid response"
        }
        return Amount(value: value, unit: .winston)
    }

    static func anchor() async throws -> String {
        let target = API(route: .txAnchor)
        let response = try await HttpClient.request(target)
        
        let anchor = String(decoding: response.data, as: UTF8.self)
        return anchor
    }
}

extension Array where Element == Transaction.Tag {
    var combined: String {
        reduce(into: "") { str, tag in
            str += tag.name
            str += tag.value
        }
    }
}
