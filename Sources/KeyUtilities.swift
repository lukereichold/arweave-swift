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

func deepHash(data: DeepHashChunk) -> Data {
    if case .dataArray(let dataArray) = data {
        let tag = concatData(data: [
            "list".data(using: .utf8)!,
            String(dataArray.count).data(using: .utf8)!
        ])
        
        return deepHashChunks(chunks: dataArray, acc: SHA384.hash(data: tag).data)
    }
    
    if case .data(let dataItem) = data {
        let tag = concatData(data: [
            "blob".data(using: .utf8)!,
            dataItem.count.description.data(using: .utf8)!
        ])
        
        let taggedHash = concatData(data: [
            SHA384.hash(data: tag).data,
            SHA384.hash(data: dataItem).data
        ])
        
        return SHA384.hash(data: taggedHash).data
    }
    
    return "".data(using: .utf8)!
}

func deepHashChunks(chunks: DeepHashChunks, acc: Data) -> Data {
    if chunks.count < 1 {
        return acc
    }
    
    let hashPair = concatData(data: [
        acc,
        deepHash(data: chunks.first!)
    ])
    let newAcc = SHA384.hash(data: hashPair).data
    return deepHashChunks(chunks: Array(chunks[1..<chunks.count]), acc: newAcc)
}

enum DeepHashChunk {
    case data(Data)
    case dataArray(DeepHashChunks)
}
typealias DeepHashChunks = Array<DeepHashChunk>
