import Foundation
import Moya

struct API {
    static var host: URL?
    let route: Route
}

enum Route {
    case txAnchor
    case transaction(id: TransactionId)
    case transactionData(id: TransactionId)
    case transactionStatus(id: TransactionId)
    case lastTransactionId(walletAddress: Address)
    case walletBalance(walletAddress: Address)
    case reward(Transaction.PriceRequest)
    case commit(Transaction)
}

extension API: TargetType {
    var baseURL: URL {
        API.host ?? URL(string: "https://arweave.net")!
    }
    
    var path: String {
        switch route {
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
        case let .reward(request):
            var path = "/price/\(String(request.bytes))"
            if let target = request.target {
                path.append("/\(target.address)")
            }
            return path
        case .commit:
            return "/tx"
        }
    }
    
    var method: Moya.Method {
        if case Route.commit = route {
            return .post
        } else {
            return .get
        }
    }
    
    var sampleData: Data { Data() }
    
    var task: Task {
        if case let Route.commit(transaction) = route {
            return .requestJSONEncodable(transaction)
        } else {
            return .requestPlain
        }
    }
    
    var headers: [String: String]? {
        ["Content-type": "application/json"]
    }
}
