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

func deepHash(buffers: [Data]) -> Data {
    precondition(!buffers.isEmpty)
    let tag = "list".data(using: .utf8)! + String(buffers.count).data(using: .utf8)!
    return deepHashChunks(chunks: buffers, acc: tag)
}

func deepHash(buffer: Data) -> Data {
    let tag = "blob".data(using: .utf8)! + String(buffer.count).data(using: .utf8)!
    let taggedHash = Data(SHA384.hash(data: tag)) + Data(SHA384.hash(data: buffer))
    return Data(SHA384.hash(data: taggedHash))
}

func deepHashChunks(chunks: [Data], acc: Data) -> Data {
    guard chunks.count >= 1 else { return acc }
    var currentChunks = chunks

    let first = currentChunks.removeFirst()
    let hashPair = acc + deepHash(buffer: first)
    let newAcc = Data(SHA384.hash(data: hashPair))
    return deepHashChunks(chunks: currentChunks, acc: newAcc)
}
