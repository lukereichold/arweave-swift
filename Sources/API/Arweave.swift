import Foundation

public struct Arweave {
    static let shared = Arweave()
    private init() {}
    public static var baseUrl = URL(string: "http://localhost:1984")!
    
    func request(for route: Route) -> Request {
        return Request(route: route)
    }
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

extension Arweave {
    
    struct Request {
        
        var route: Route
        
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
        
        var url: URL {
            baseUrl.appendingPathComponent(path)
        }
        
        var method: String {
            if case Route.commit = route {
                return "post"
            } else {
                return "get"
            }
        }
        
        var body: Data? {
            if case let Route.commit(transaction) = route {
                return try? JSONEncoder().encode(transaction)
            } else {
                return nil
            }
        }
        
        var headers: [String: String]? {
            ["Content-type": "application/json"]
        }
    }
}
