import Foundation

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
}

extension Transaction {
    init(data: Data) {
        self.data = data.base64URLEncodedString()
    }
    init(amount: Amount, target: Address) {
        self.quantity = String(format: "%.f", amount.value)
        self.target = target.address
    }
}

extension LosslessStringConvertible {
    var string: String { .init(self) }
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

    static func price(for request: Transaction.PriceRequest,
                      completion: @escaping Response<Amount>) {

        let target = API(route: .reward(request))
        HttpClient.request(target) { response in
            guard let cost = try? response.map(Double.self) else {
                completion(.failure("Unexpected response type in: \(#function)"))
                return
            }
            let price = Amount(value: cost, unit: .winston)
            completion(.success(price))
        } error: { error in
            completion(.failure(error))
        }
    }

}
