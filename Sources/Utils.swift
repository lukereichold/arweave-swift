//
//  File.swift
//
//
//  Created by David Choi on 11/6/21.
//

import Foundation

public func concatBuffers(buffers: [Data]) -> Data {
    var total_length = 0
    for i in 0..<buffers.count {
        total_length += buffers[i].count
    }
    
    var temp = Data(capacity: total_length)
    var offset = 0
    
    temp.insert(contentsOf: Data(buffers[0]), at: offset)
    offset += buffers[0].count
    
    for i in 1..<buffers.count {
        temp.insert(contentsOf: Data(buffers[i]), at: offset)
        offset += buffers[i].count
    }
    return temp
}

public func bufferTob64(buffer: Data) -> String {
    return Data(buffer).base64URLEncodedString()
}

public func bufferTob64Url(buffer: Data) -> String {
    return b64UrlEncode(str: bufferTob64(buffer: buffer))
}

public func b64UrlEncode(str: String) -> String {
    return str
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "-")
        .replacingOccurrences(of: "=", with: "")
}
