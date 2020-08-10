import Foundation

typealias TransactionId = String
typealias Base64EncodedString = String

extension Transaction {
    struct PriceRequest {
        let bytes: Int = 0
        let target: Address?
    }
}

struct Transaction: Codable {
    let id: TransactionId
    let last_tx: TransactionId
    let owner: String
    let tags: [Tag]
    let target: String
    let quantity: String
    let data: String
    let reward: String
    let signature: String

    struct Tag: Codable {
        let name: String
        let value: String
    }
}

extension Transaction {

    typealias Response<T> = (Result<T, Error>) -> Void

    static func find(with txId: TransactionId,
                     completion: @escaping Response<Transaction>) {

        let target = API(route: .transaction(id: txId))
        HttpClient.request(target) { response in
            guard let tx = try? response.map(Transaction.self) else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            completion(.success(tx))
        } error: { error in
            completion(.failure(error))
        }
    }

    static func data(for txId: TransactionId,
                     completion: @escaping Response<Base64EncodedString>) {

        let target = API(route: .transactionData(id: txId))
        HttpClient.request(target) { response in
            guard let txData = try? response.mapString() else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            completion(.success(txData))
        } error: { error in
            completion(.failure(error))
        }
    }

    static func status(of txId: TransactionId,
                       completion: @escaping Response<Transaction.Status>) {

        let target = API(route: .transactionStatus(id: txId))
        HttpClient.request(target, shouldFilterStatusCodes: false) { response in

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
        } error: { error in
            completion(.failure(error))
        }
    }

}
