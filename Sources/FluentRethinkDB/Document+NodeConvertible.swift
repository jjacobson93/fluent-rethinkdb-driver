//
//  Document+NodeConvertible.swift
//  FluentRethinkDB
//
//  Created by Jeremy Jacobson on 11/18/16.
//
//

import Foundation
import RethinkDB
import Node

extension Document: NodeConvertible {
    public init(node: Node, in context: Context) throws {
        guard case let .object(obj) = node else {
            throw NodeError.unableToConvert(node: node, expected: "Object")
        }
        
        
        var dict = [String: Value]()
        for (key, value) in obj {
            dict[key] = try Document.reqlValue(from: value)
        }
        self = Document(dict)
    }
    
    public func makeNode(context: Context) throws -> Node {
        var dict = [String: Node]()
        for (key, value) in self {
            dict[key] = try Document.node(from: value)
        }
        return .object(dict)
    }
    
    private static func node(from reqlValue: ReqlValue) throws -> Node {
        switch reqlValue {
        case .null,
             .nothing:
            return .null
        case .bool(let b):
            return .bool(b)
        case .string(let s):
            return .string(s)
        case .data(let data):
            let bytes = data.withUnsafeBytes({ [UInt8](UnsafeBufferPointer(start: $0, count: data.count)) })
            return .bytes(bytes)
        case .number(let num):
            switch num {
            case .int(let i): return .number(.int(Int(i)))
            case .uint(let i): return .number(.uint(UInt(i)))
            case .float(let f): return .number(.double(Double(f)))
            case .double(let d): return .number(.double(d))
            }
        case .array(let arr):
            return .array(try arr.map({ try Document.node(from: $0) }))
        case .date(let d):
            return try d.makeNode()
        case .document(let doc):
            return try doc.makeNode()
        case .geometry(let geo):
            return try geo.makeNode()
        }
    }
    
    private static func reqlValue(from node: Node) throws -> ReqlValue {
        switch node {
        case .null:
            return .null
        case .bool(let b):
            return .bool(b)
        case .string(let s):
            return .string(s)
        case .bytes(let bytes):
            return .data(Data(bytes: bytes))
        case .number(let num):
            switch num {
            case .int(let i): return .number(.int(Int64(i)))
            case .uint(let u): return .number(.uint(UInt64(u)))
            case .double(let d): return .number(.double(d))
            }
        case .array(let arr):
            return .array(try arr.map({ try Document.reqlValue(from: $0) }))
        case .object:
            if let reqlTypeRaw: String = try? node.extract(ReqlType.key),
                let reqlType = ReqlType(rawValue: reqlTypeRaw) {
                switch reqlType {
                case .time:
                    return .date(try Date(node: node, in: EmptyNode))
                case .binary:
                    return .data(try Data(node: node, in: EmptyNode))
                case .geometry:
                    return .geometry(try Geometry(node: node, in: EmptyNode))
                }
            }
            return .document(try Document(node: node, in: EmptyNode))
        }
    }
}
