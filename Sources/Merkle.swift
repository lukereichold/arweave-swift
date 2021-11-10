//
//  File.swift
//  
//
//  Created by David Choi on 11/6/21.
//

import Foundation
import CryptoKit

struct Chunk {
    let dataHash: Data
    let minByteRange: Int
    let maxByteRange: Int
}

class BranchNode: MerkelNode {
    var id: Data
    var type: BranchOrLeaf = BranchOrLeaf.branch
    let byteRange: Int
    var maxByteRange: Int
    let leftChild: MerkelNode?
    let rightChild: MerkelNode?
    
    init(id: Data, byteRange: Int, maxByteRange: Int, leftChild: MerkelNode? = nil, rightChild: MerkelNode? = nil) {
        self.id = id
        self.byteRange = byteRange
        self.maxByteRange = maxByteRange
        self.leftChild = leftChild
        self.rightChild = rightChild
    }
}

class LeafNode: MerkelNode {
    var id: Data
    let dataHash: Data
    var type: BranchOrLeaf = BranchOrLeaf.leaf
    let minByteRange: Int
    var maxByteRange: Int
    
    init(id: Data, dataHash: Data, minByteRange: Int, maxByteRange: Int) {
        self.id = id
        self.dataHash = dataHash
        self.minByteRange = minByteRange
        self.maxByteRange = maxByteRange
    }
}

protocol MerkelNode {
    var id: Data { get set }
    var maxByteRange: Int { get set }
    var type: BranchOrLeaf { get set }
}

enum BranchOrLeaf {
    case branch
    case leaf
}
enum BranchOrLeafError: Error {
    case UnknownNodeType
}

struct Proof {
    let offset: Int
    let proof: Data
}

let MAX_CHUNK_SIZE = 256 * 1024
let MIN_CHUNK_SIZE = 32 * 1024
let NOTE_SIZE = 32
let HASH_SIZE = 32

func chunkData(data: Data) -> [Chunk] {
    var chunks = [Chunk]()
    
    var rest = data
    var cursor = 0
    
    while(rest.count >= MAX_CHUNK_SIZE) {
        var chunkSize = MAX_CHUNK_SIZE
        
        let nextChunkSize = rest.count - MAX_CHUNK_SIZE
        if (nextChunkSize > 0 && nextChunkSize < MIN_CHUNK_SIZE) {
            chunkSize = Int(Double(rest.count / 2).rounded())
        }
        
        let chunk = rest.subdata(in: 0..<chunkSize)
        let dataHash = SHA256.hash(data: chunk)
        cursor += chunk.count
        chunks.append(Chunk(dataHash: dataHash.data, minByteRange: cursor - chunk.count, maxByteRange: cursor))
        rest = rest.subdata(in: (chunkSize <= 0 ? 0 : chunkSize - 1)..<rest.count)
    }
    
    chunks.append(Chunk(dataHash: SHA256.hash(data: rest).data, minByteRange: cursor, maxByteRange: cursor + rest.count))
    return chunks
}

func generateLeaves(chunks: [Chunk]) -> [LeafNode] {
    return chunks.map { chunk in
        var idData = [Data]()
        idData.append(chunk.dataHash)
        idData.append(intToBuffer(note: chunk.maxByteRange))
        
        return LeafNode(
            id: hashId(data: idData),
            dataHash: chunk.dataHash,
            minByteRange: chunk.minByteRange,
            maxByteRange: chunk.maxByteRange
        )
    }
}

func hashId(data: [Data]) -> Data {
    let data = concatBuffers(buffers: data)
    return Data(SHA256.hash(data: data))
}

func intToBuffer(note: Int) -> Data {
    var note = note
    var buffer = Data(capacity: NOTE_SIZE)
    
    for i in stride(from: buffer.count - 1, through: 0, by: -1) {
        let byte = note % 256
        buffer[i] = UInt8(byte)
        note = (note - byte) / 256
    }
    
    return buffer
}

// of leafs or branches
func buildLayers(nodes: [MerkelNode], level: Int = 0) -> MerkelNode {
    if nodes.count < 2 {
        return hashBranch(left: nodes[0])
    }
    
    var nextLayer = [MerkelNode]()
    for i in stride(from: 0, to: nodes.count, by: 2) {
        nextLayer.append(hashBranch(left: nodes[i], right: nodes[i + 1]))
    }
    
    return buildLayers(nodes: nextLayer, level: level + 1)
}

func generateTransactionChunks(data: Data) -> Chunks {
    var chunks = chunkData(data: data)
    let leaves = generateLeaves(chunks: chunks)
    let root = buildLayers(nodes: leaves)
    var proofs = generateProofs(root: root)
    
    if chunks.count > 0 {
        let lastChunk = chunks.last
        if ((lastChunk!.maxByteRange - lastChunk!.minByteRange) == 0) {
            chunks.remove(at: chunks.count - 1)
            proofs.remove(at: proofs.count - 1)
        }
    }
    
    return Chunks(data_root: root.id, chunks: chunks, proofs: proofs)
}

func generateProofs(root: MerkelNode) -> [Proof] {
    var proofs: [Proof] = [Proof]()
    do {
        proofs = try resolveBranchProofs(node: root)
    } catch {
        print("failed to resolve branch proofs \(error)")
    }
    return proofs
}

func resolveBranchProofs(node: MerkelNode, proof: Data = Data(), depth: Int = 0) throws -> [Proof] {
    if node.type == BranchOrLeaf.leaf {
        let dataHash = (node as! LeafNode).dataHash
        return [
            Proof(offset: node.maxByteRange - 1, proof: concatBuffers(buffers: [proof, dataHash, intToBuffer(note: node.maxByteRange)]))
        ]
    }
    
    if node.type == BranchOrLeaf.branch {
        let branch = (node as! BranchNode)
        
        var buffers = [
            proof,
            intToBuffer(note: branch.byteRange)
        ]
        if let leftChild = branch.leftChild {
            buffers.append(leftChild.id)
        }
        if let rightChild = branch.rightChild {
            buffers.append(rightChild.id)
        }
        let partialProof = concatBuffers(buffers: buffers)
        
        var resolvedProofs = [[Proof]]()
        if let leftChild = branch.leftChild {
            resolvedProofs.append(try resolveBranchProofs(node: leftChild, proof: partialProof, depth: depth + 1))
        }
        if let rightChild = branch.rightChild {
            resolvedProofs.append(try resolveBranchProofs(node: rightChild, proof: partialProof, depth: depth + 1))
        }
        return Array(resolvedProofs.joined())
    }
    
    throw BranchOrLeafError.UnknownNodeType
}

func hashBranch(left: MerkelNode, right: MerkelNode? = nil) -> MerkelNode {
    if right == nil {
        return BranchNode(
                id: hashId(data: [
                hashId(data: [left.id]),
                hashId(data: [intToBuffer(note: left.maxByteRange)]),
            ]),
            byteRange: left.maxByteRange,
            maxByteRange: left.maxByteRange,
            leftChild: left)
    }
    
    let branch = BranchNode(
        id: hashId(data: [
            hashId(data: [left.id]),
            hashId(data: [right!.id]),
            hashId(data: [intToBuffer(note: left.maxByteRange)]),
        ]),
        byteRange: left.maxByteRange,
        maxByteRange: right!.maxByteRange,
        leftChild: left,
        rightChild: right
    )
    return branch
}
