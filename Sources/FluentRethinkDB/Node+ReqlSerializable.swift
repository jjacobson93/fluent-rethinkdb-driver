//
//  Node+ReqlSerializable.swift
//  FluentRethinkDB
//
//  Created by Jeremy Jacobson on 11/3/16.
//
//

import Foundation
import Node
import RethinkDB

extension Node: ReqlSerializable {
    public var json: Any {
        switch self {
        case .array(let array):
            return array.map({ $0.json })
        case .bool(let b):
            return b
        case .bytes(let bytes):
            return Data(bytes: bytes)
        case .null:
            return NSNull()
        case .number(let number):
            switch number {
            case .int(let i): return i
            case .double(let d): return d
            case .uint(let u): return u
            }
        case .object(let obj):
            var dict = [String: Any]()
            for (key, val) in obj {
                dict[key] = val.json
            }
            return dict
        case .string(let s):
            return s
        }
    }
}
