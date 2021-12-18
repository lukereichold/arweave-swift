import Foundation
import CryptoKit

public struct Chunks {
    let data_root: Data
    let chunks: [Chunk]
    let proofs: [Proof]
}

public typealias TransactionId = String
public typealias Base64EncodedString = String
public typealias Base64URLEncodedString = String
public struct Tag: Codable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

public extension Transaction {

    struct PriceRequest {
        
        public init(bytes: Int = 0, target: Address? = nil) {
            self.bytes = bytes
            self.target = target
        }
        
        public var bytes: Int = 0
        public var target: Address?
    }
}

public struct Transaction: Codable {
    public var format = 2
    public var id: TransactionId = ""
    public var last_tx: TransactionId = ""
    public var owner: String = ""
    public var tags = [Tag]()
    public var target: String = ""
    public var quantity: String = "0"
    public var data: String? = "" // do not remove optional. decode will fail if data comes back empty
    public var data_root: String = ""
    public var data_size: String = "0"
    public var reward: String = ""
    public var signature: String = ""
    public var chunks: Chunks? = nil

    private enum CodingKeys: String, CodingKey {
        case format, id, last_tx, owner, tags, target, quantity, data, data_root, data_size, reward, signature
    }

    public var priceRequest: PriceRequest {
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
        tx.tags = tx.tags.map { tag in
            Tag(name: tag.name.base64URLEncoded, value: tag.value.base64URLEncoded)
        }
        tx.data_size = tx.data!.lengthOfBytes(using: .utf8).description
        
        let signedMessage = try wallet.sign(try await tx.signatureBody())
        tx.signature = signedMessage.base64URLEncodedString()
        tx.id = SHA256.hash(data: signedMessage).data
            .base64URLEncodedString()
        return tx
    }

    func commit() async throws -> HttpResponse {
        guard !signature.isEmpty else {
            throw "Missing signature on transaction."
        }

        let commit = Arweave.shared.request(for: .commit(self))
        return try await HttpClient.request(commit)
    }

    mutating private func signatureBody() async throws -> Data {
        try prepareChunks(data: self.rawData)
        
        return deepHash(data: DeepHashChunk.dataArray([
            DeepHashChunk.data(format.description.data(using: .utf8)!),
            DeepHashChunk.data(Data(base64URLEncoded: owner)!),
            DeepHashChunk.data(Data(base64URLEncoded: target)!),
            DeepHashChunk.data(quantity.data(using: .utf8)!),
            DeepHashChunk.data(reward.data(using: .utf8)!),
            DeepHashChunk.data(Data(base64URLEncoded: last_tx)!),
            DeepHashChunk.data(tags.combined.data(using: .utf8)!),
            DeepHashChunk.data(data_size.data(using: .utf8)!),
            DeepHashChunk.data(Data(base64URLEncoded: data_root)!)
        ]))
    }
}

public extension Transaction {
    mutating func prepareChunks(data: Data) throws -> Void {
        if self.chunks == nil && data.count > 0 {
            self.chunks = try generateTransactionChunks(data: data)
            self.data_root = bufferTob64Url(buffer: self.chunks!.data_root)
        }
        
        if self.chunks == nil && data.count == 0 {
            self.chunks = Chunks(data_root: Data(), chunks: [Chunk](), proofs: [Proof]())
            self.data_root = ""
        }
    }

    static func find(_ txId: TransactionId) async throws -> Transaction {
        let findEndpoint = Arweave.shared.request(for: .transaction(id: txId))
        let response = try await HttpClient.request(findEndpoint)
        return try JSONDecoder().decode(Transaction.self, from: response.data)
    }

    static func data(for txId: TransactionId) async throws -> Base64URLEncodedString {
        let target = Arweave.shared.request(for: .transactionData(id: txId))
        let response = try await HttpClient.request(target)
        //return String(decoding: response.data, as: UTF8.self)
        //return response.data.base64EncodedString()
        return response.data.base64URLEncodedString()
    }

    static func status(of txId: TransactionId) async throws -> Transaction.Status {

        let target = Arweave.shared.request(for: .transactionStatus(id: txId))
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
        let target = Arweave.shared.request(for: .reward(request))
        let response = try await HttpClient.request(target)

        let costString = String(decoding: response.data, as: UTF8.self)
        guard let value = Double(costString) else {
            throw "Invalid response"
        }
        return Amount(value: value, unit: .winston)
    }

    static func anchor() async throws -> String {
        let target = Arweave.shared.request(for: .txAnchor)
        let response = try await HttpClient.request(target)
        
        let anchor = String(decoding: response.data, as: UTF8.self)
        return anchor
    }
}

extension Array where Element == Tag {
    var combined: String {
        reduce(into: "") { str, tag in
            str += tag.name
            str += tag.value
        }
    }
}
