import Foundation
import CryptoKit

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
}

public extension String {
    var base64URLEncoded: String {
        Data(utf8).base64URLEncodedString()
    }
    
    var base64URLDecoded: String {
        guard let data = Data(base64URLEncoded: self) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

extension Array where Element == Data {
    var combined: Data {
       reduce(.init(), +)
    }
}
