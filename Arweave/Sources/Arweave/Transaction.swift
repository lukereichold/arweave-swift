import Foundation
import CryptoKit

typealias TransactionId = String
typealias Base64EncodedString = String

extension Transaction {
    struct PriceRequest {
        var bytes: Int = 0
        var target: Address? = nil
    }
}

struct Transaction: Codable {
    var id: TransactionId = ""
    var last_tx: TransactionId = ""
    var owner: String = ""
    var tags = [Tag]()
    var target: String = ""
    var quantity: String = ""
    var data: String = ""
    var reward: String = ""
    var signature: String = ""

    struct Tag: Codable {
        let name: String
        let value: String
    }

    var priceRequest: PriceRequest {
        PriceRequest(bytes: data.utf8.count,
                     target: Address(address: target))
    }
}

let queue = DispatchQueue(label: "com.arweave.sdk", attributes: .concurrent)

extension Transaction {
    init(data: Data) {
        self.data = data.base64URLEncodedString()
    }

    init(amount: Amount, target: Address) {
        self.quantity = amount.string
        self.target = target.address
    }

    func sign(with wallet: Wallet) throws -> Transaction {
        var tx = self

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        Transaction.anchor() { result in
            tx.last_tx = (try? result.get()) ?? ""
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        Transaction.price(for: self.priceRequest) { result in
            tx.reward = (try? result.get().string) ?? ""
            dispatchGroup.leave()
        }

        dispatchGroup.wait()

        let signedMessage = try wallet.sign(self.signatureBody())
        tx.signature = signedMessage.base64URLEncodedString()
        tx.id = SHA256.hash(data: signedMessage).data
            .base64URLEncodedString()
        tx.owner = wallet.address.description
        return tx
    }

    func commit(completion: @escaping Response<Bool>) {
        guard !signature.isEmpty else {
            completion(.failure("Missing signature value on transction."))
            return
        }

        HttpClient.request(API(route: .commit(self))) { result in
            guard let tx = try? result.get(), tx.statusCode == 200 else {
                completion(.failure("Failed to submit transaction."))
                return
            }
            completion(.success(true))
        }
    }

    private func signatureBody() -> Data {
        let tagsString = tags.reduce(into: "") { str, tag in
            str += tag.name.base64URLEncoded
            str += tag.value.base64URLEncoded
        }
        return [
            owner.base64URLEncoded,
            target.base64URLEncoded,
            data.base64URLEncoded,
            quantity,
            reward,
            last_tx.base64URLEncoded,
            tagsString
            ].joined().data(using: .utf8) ?? Data()
    }
}

extension Transaction {

    typealias Response<T> = (Swift.Result<T, Error>) -> Void

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
