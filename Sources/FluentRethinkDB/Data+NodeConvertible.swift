//
//  Data+NodeConvertible.swift
//  FluentRethinkDB
//
//  Created by Jeremy Jacobson on 11/21/16.
//
//

import Foundation
import Node
import RethinkDB

extension Data: NodeConvertible {
    public init(node: Node, in context: Context) throws {
        if case .bytes(let bytes) = node {
            self = Data(bytes: bytes)
            return
        }
        
        let data: String = try node.extract("data")
        self = Data.from(["data": data])
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            ReqlType.key: ReqlType.binary.rawValue,
            "data": self.base64EncodedString()
        ])
    }
}
