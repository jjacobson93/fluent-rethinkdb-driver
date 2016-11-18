//
//  Date+NodeConvertible.swift
//  FluentRethinkDB
//
//  Created by Jeremy Jacobson on 11/18/16.
//
//

import Foundation
import Node

extension Date: NodeConvertible {
    public init(node: Node, in context: Context) throws {
        let epochTime: Double = try node.extract("epoch_time")
        self = Date.from(["epoch_time": epochTime])
    }
    
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "$reql_type$": "TIME",
            "epoch_time": self.timeIntervalSince1970,
            "timezone": "+00:00"
        ])
    }
}
