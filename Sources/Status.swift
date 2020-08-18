import Foundation

public extension Transaction {
    enum Status {
        case accepted(data: Data)
        case pending
        case notFound
        case failed
        case invalid
    }
}

public extension Transaction.Status {
    struct Data: Codable {
        let block_height: Int
        let block_indep_hash: String
        let number_of_confirmations: Int
    }
}

extension Transaction.Status: RawRepresentable {
    public enum RawStatus { case status(Int), data(Data) }
    public typealias RawValue = RawStatus

    public init?(rawValue: RawValue) {
        switch rawValue {
        case let .data(data):
            self = .accepted(data: data)
        case let .status(code):
            switch code {
            case 202: self = .pending
            case 404: self = .notFound
            case 410: self = .failed
            default:  self = .invalid
            }
        }
    }

    public var rawValue: RawValue {
        switch self {
        case .accepted(let data): return .data(data)
        case .pending: return .status(202)
        case .notFound: return .status(404)
        case .failed: return .status(410)
        case .invalid: return .status(Int.max)
        }
    }
}
