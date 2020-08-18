import Foundation
import CryptoKit

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
}

extension String {
    var base64URLEncoded: String {
        Data(utf8).base64URLEncodedString()
    }
}

extension Array where Element == Data {
    var combined: Data {
       reduce(.init(), +)
    }
}
