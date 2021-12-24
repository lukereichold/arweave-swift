//
//  File.swift
//
//
//  Created by David Choi on 11/6/21.
//

import Foundation
import CryptoKit
import zlib

struct Chunk {
    let dataHash: Data
    let minByteRange: Int
    let maxByteRange: Int
}

class BranchNode {
    var id: Data
    var type: MerkleNode? = nil
    let byteRange: Int
    var maxByteRange: Int
    let leftChild: MerkleNode?
    let rightChild: MerkleNode?
    
    init(id: Data, byteRange: Int, maxByteRange: Int, leftChild: MerkleNode? = nil, rightChild: MerkleNode? = nil) {
        self.id = id
        self.byteRange = byteRange
        self.maxByteRange = maxByteRange
        self.leftChild = leftChild
        self.rightChild = rightChild
    }
}

class LeafNode {
    var id: Data
    let dataHash: Data
    var type: MerkleNode? = nil
    let minByteRange: Int
    var maxByteRange: Int
    
    init(id: Data, dataHash: Data, minByteRange: Int, maxByteRange: Int) {
        self.id = id
        self.dataHash = dataHash
        self.minByteRange = minByteRange
        self.maxByteRange = maxByteRange
    }
}

enum MerkleNode {
    case branchNode(BranchNode)
    case leafNode(LeafNode)
}

enum BranchOrLeafError: Error {
    case UnknownNodeType
}

struct Proof {
    let offset: Int
    let proof: Data
}

enum ProofType {
    case item(Proof)
    case array([Proof])
}

enum HashDataType {
    case data(Data)
    case dataArray([Data])
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
            chunkSize = Int(ceil(Double(rest.count / 2)))
        }
        
        let chunk = rest.subdata(in: 0..<chunkSize)
        let dataHash = SHA256.hash(data: chunk)
        cursor += chunk.count
        chunks.append(Chunk(dataHash: dataHash.data, minByteRange: cursor - chunk.count, maxByteRange: cursor))
        rest = rest.subdata(in: chunkSize..<rest.count)
    }
    
    chunks.append(Chunk(dataHash: SHA256.hash(data: rest).data, minByteRange: cursor, maxByteRange: cursor + rest.count))
    return chunks
}

func generateLeaves(chunks: [Chunk]) -> [LeafNode] {
    return chunks.map { chunk in
        let leaf = LeafNode(
            id: hash(data: HashDataType.dataArray([hash(data: HashDataType.data(chunk.dataHash)), hash(data: HashDataType.data(intToBuffer(note: chunk.maxByteRange)))])),
            dataHash: chunk.dataHash,
            minByteRange: chunk.minByteRange,
            maxByteRange: chunk.maxByteRange
        )
        leaf.type = MerkleNode.leafNode(leaf)
        return leaf
    }
}

func hash(data: HashDataType) -> Data {
    switch data {
    case .dataArray(let dataArray):
        let localData = concatBuffers(buffers: dataArray)
        return Data(SHA256.hash(data: localData))
    case .data(let dataItem):
        let localData = concatBuffers(buffers: [dataItem])
        return Data(SHA256.hash(data: localData))
    }
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
func buildLayers(nodes: [MerkleNode], level: Int = 0) throws -> MerkleNode {
    let nodesCount = nodes.count
    if nodesCount < 2 {
        return nodes[0]
    }
    
    var nextLayer = [MerkleNode]()
    
    for i in stride(from: 0, to: nodesCount, by: 2) {
        nextLayer.append(try hashBranch(left: nodes[i], right: i + 1 < nodesCount ? nodes[i + 1] : nil))
    }
    
    return try buildLayers(nodes: nextLayer, level: level + 1)
}

func generateTransactionChunks(data: Data) throws -> Chunks {
    var chunks = chunkData(data: data)
    let leaves = generateLeaves(chunks: chunks)
    let root = try buildLayers(nodes: leaves.map { leaf in
        leaf.type!
    })
    var proofs = generateProofs(root: root)
    
    if chunks.count > 0 {
        let lastChunk = chunks.last
        if ((lastChunk!.maxByteRange - lastChunk!.minByteRange) == 0) {
            chunks.remove(at: chunks.count - 1)
            proofs.remove(at: proofs.count - 1)
        }
    }
    
    var rootId: Data?
    switch root {
    case .leafNode(let leaf):
        rootId = leaf.id
    case .branchNode(let branch):
        rootId = branch.id
    }
    return Chunks(data_root: rootId!, chunks: chunks, proofs: proofs)
}

func generateProofs(root: MerkleNode) -> [Proof] {
    do {
        let proofs = try resolveBranchProofs(node: root)
        switch proofs {
        case .item(let proofItem):
            return [proofItem]
        case .array(let proofArray):
            return proofArray
        }
    } catch {
        print("failed to resolve branch proofs \(error)")
    }
    return []
}

func resolveBranchProofs(node: MerkleNode, proof: Data = Data(), depth: Int = 0) throws -> ProofType {
    switch node {
    case .leafNode(let leaf):
        return ProofType.item(
            Proof(offset: leaf.maxByteRange - 1, proof: concatBuffers(buffers: [proof, leaf.dataHash, intToBuffer(note: leaf.maxByteRange)]))
        )
    case .branchNode(let branch):
        var buffers = [
            proof
        ]
        if let leftChild = branch.leftChild {
            if case .leafNode(let leftLeaf) = leftChild {
                buffers.append(leftLeaf.id)
            } else if case .branchNode(let leftBranch) = leftChild {
                buffers.append(leftBranch.id)
            }
        }
        if let rightChild = branch.rightChild {
            if case .leafNode(let rightLeaf) = rightChild {
                buffers.append(rightLeaf.id)
            } else if case .branchNode(let rightBranch) = rightChild {
                buffers.append(rightBranch.id)
            }
        }
        buffers.append(intToBuffer(note: branch.byteRange))
        let partialProof = concatBuffers(buffers: buffers)
        
        var resolvedProofs = [Proof]()
        if let leftChild = branch.leftChild {
            let result = try resolveBranchProofs(node: leftChild, proof: partialProof, depth: depth + 1)
            if case .item(let item) = result {
                resolvedProofs.append(item)
            }
        }
        if let rightChild = branch.rightChild {
            let result = try resolveBranchProofs(node: rightChild, proof: partialProof, depth: depth + 1)
            if case .item(let item) = result {
                resolvedProofs.append(item)
            }
        }
        return ProofType.array(resolvedProofs)
    }
}

func hashBranch(left: MerkleNode, right: MerkleNode? = nil) throws -> MerkleNode {
    if right == nil {
        switch left {
        case .leafNode(let leaf):
            let branch = BranchNode(id: leaf.id, byteRange: leaf.maxByteRange, maxByteRange: leaf.maxByteRange, leftChild: nil, rightChild: nil)
            branch.type = MerkleNode.branchNode(branch)
            return branch.type!
        case .branchNode(let branch):
            return branch.type!
        }
    } else {
        var leftLeaf: LeafNode?
        var leftBranch: BranchNode?
        var rightLeaf: LeafNode?
        var rightBranch: BranchNode?
        
        switch left {
        case .leafNode(let leaf):
            leftLeaf = leaf
        case .branchNode(let branch):
            leftBranch = branch
        }
        
        switch right! {
        case .leafNode(let leaf):
            rightLeaf = leaf
        case .branchNode(let branch):
            rightBranch = branch
        }
        
        let branch = BranchNode(
            id: hash(data: HashDataType.dataArray([
                hash(data: leftLeaf != nil ? HashDataType.data(leftLeaf!.id) : HashDataType.data(leftBranch!.id)),
                hash(data: rightLeaf != nil ? HashDataType.data(rightLeaf!.id) : HashDataType.data(rightBranch!.id)),
                hash(data: HashDataType.data(intToBuffer(note: leftLeaf != nil ? leftLeaf!.maxByteRange : leftBranch!.maxByteRange))),
            ])),
            byteRange: leftLeaf != nil ? leftLeaf!.maxByteRange : leftBranch!.maxByteRange,
            maxByteRange: rightLeaf != nil ? rightLeaf!.maxByteRange : rightBranch!.maxByteRange,
            leftChild: left,
            rightChild: right
        )
        branch.type = MerkleNode.branchNode(branch)
        
        return branch.type!
    }
}
