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

func concatData(data: [Data]) -> Data {
    var length = 0
    for d in data {
        length += d.count
    }
    
    var temp = Data(capacity: length)
    for d in data {
        temp.append(d)
    }
    
    return temp
}

func deepHash(data: [Data]) -> Data {
    if data.count > 1 {
        let tag = concatData(data: [
            "list".data(using: .utf8)!,
            String(data.count).data(using: .utf8)!
        ])
        
        return deepHashChunks(chunks: data, acc: SHA384.hash(data: tag).data)
    }
    
    let tag = concatData(data: [
        "blob".data(using: .utf8)!,
        data.first!.count.description.data(using: .utf8)!
    ])
    
    let taggedHash = concatData(data: [
        SHA384.hash(data: tag).data,
        SHA384.hash(data: data.first!).data
    ])
    
    return SHA384.hash(data: taggedHash).data
}

func deepHashChunks(chunks: [Data], acc: Data) -> Data {
    if chunks.count < 1 {
        return acc
    }
    
    let hashPair = concatData(data: [
        acc,
        deepHash(data: [chunks.first!])
    ])
    let newAcc = SHA384.hash(data: hashPair).data
    return deepHashChunks(chunks: Array(chunks.prefix(through: 1)), acc: newAcc)
}
