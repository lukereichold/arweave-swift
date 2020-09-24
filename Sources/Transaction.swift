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

let queue = DispatchQueue(label: "com.arweave.sdk", attributes: .concurrent)

public extension Transaction {
    init(data: Data) {
        self.rawData = data
    }

    init(amount: Amount, target: Address) {
        self.quantity = amount.string
        self.target = target.address
    }

    func sign(with wallet: Wallet) throws -> Transaction {
        var tx = self
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        Transaction.anchor { result in
            tx.last_tx = (try? result.get()) ?? ""
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        tx.data = rawData.base64URLEncodedString()
        Transaction.price(for: self.priceRequest) { result in
            tx.reward = (try? result.get().string) ?? ""
            dispatchGroup.leave()
        }

        dispatchGroup.wait()

        tx.owner = wallet.ownerModulus
        let signedMessage = try wallet.sign(tx.signatureBody())
        tx.signature = signedMessage.base64URLEncodedString()
        tx.id = SHA256.hash(data: signedMessage).data
            .base64URLEncodedString()
        return tx
    }

    func commit(completion: @escaping (VoidResult) -> ()) throws {
        guard !signature.isEmpty else {
            completion(.failure("Missing signature on transaction."))
            return
        }

        HttpClient.request(API(route: .commit(self))) { result in
            guard let tx = try? result.get(), tx.statusCode == 200 else {
                completion(.failure("Failed to submit transaction"))
                return
            }
            completion(.success)
        }
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

    static func find(with txId: TransactionId,
                     completion: @escaping Response<Transaction>) {

        let target = API(route: .transaction(id: txId))
        HttpClient.request(target) { result in
            guard let tx = try? result.get().map(Transaction.self) else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            completion(.success(tx))
        }
    }

    static func data(for txId: TransactionId,
                     completion: @escaping Response<Base64EncodedString>) {

        let target = API(route: .transactionData(id: txId))
        HttpClient.request(target) { result in
            guard let txData = try? result.get().mapString() else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            completion(.success(txData))
        }
    }

    static func status(of txId: TransactionId,
                       completion: @escaping Response<Transaction.Status>) {

        let target = API(route: .transactionStatus(id: txId))
        HttpClient.request(target, shouldFilterStatusCodes: false) { result in
            guard let response = try? result.get() else {
                completion(.failure("Networking Error"))
                return
            }

            var status: Transaction.Status
            if response.statusCode == 200 {
                guard let data = try? response.map(Transaction.Status.Data.self) else {
                    completion(.failure("Unexpected response type in: \(#function)"))
                    return
                }
                status = .accepted(data: data)
            } else {
                status = Transaction.Status(rawValue: .status(response.statusCode))!
            }
            completion(.success(status))
        }
    }

    static func price(for request: Transaction.PriceRequest,
                      completion: @escaping Response<Amount>) {

        let target = API(route: .reward(request))
        HttpClient.request(target, callbackQueue: queue) { result in
            guard let cost = try? result.get().map(Double.self) else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            let price = Amount(value: cost, unit: .winston)
            completion(.success(price))
        }
    }

    static func anchor(completion: @escaping Response<String>) {
        HttpClient.request(API(route: .txAnchor), callbackQueue: queue) { result in
            guard let anchor = try? result.get().mapString() else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            completion(.success(anchor))
        }
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
