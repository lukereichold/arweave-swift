import Foundation
import Moya

enum API {
    case txAnchor
    case transaction(id: TransactionId)
    case transactionData(id: TransactionId)
    case transactionStatus(id: TransactionId)
    case lastTransactionId(walletAddress: Address)
    case walletBalance(walletAddress: Address)
    case reward(byteSize: Int, address: Address)
    case commit(transaction: Transaction)
}

extension API: TargetType {
    var baseURL: URL {
        URL(string: "https://arweave.net")!
    }
    
    var path: String {
        switch self {
        case .txAnchor:
            return "/tx_anchor"
        case let .transaction(id):
            return "/tx/\(id)"
        case let .transactionData(id):
            return "/tx/\(id)/data"
        case let .transactionStatus(id):
            return "/tx/\(id)/status"
        case let .lastTransactionId(walletAddress):
            return "/wallet/\(walletAddress)/last_tx"
        case let .walletBalance(walletAddress):
            return "/wallet/\(walletAddress)/balance"
        case let .reward(byteSize, address):
            return "/price/\(byteSize)/\(address)"
        case .commit:
            return "/tx"
        }
    }
    
    var method: Moya.Method {
        if case API.commit = self {
            return .post
        } else {
            return .get
        }
    }
    
    var sampleData: Data { Data() }
    
    var task: Task {
        if case let API.commit(transaction) = self {
            return .requestJSONEncodable(transaction)
        } else {
            return .requestPlain
        }
    }
    
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}
