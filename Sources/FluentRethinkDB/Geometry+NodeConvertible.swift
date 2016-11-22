//
//  Geometry+NodeConvertible.swift
//  FluentRethinkDB
//
//  Created by Jeremy Jacobson on 11/21/16.
//
//

import Foundation
import Node
import RethinkDB

extension Geometry: NodeConvertible {
    public init(node: Node, in context: Context) throws {
        let type: String = try node.extract("type")
        let coordinates: [Any]
        if let arr: [Double] = try? node.extract("coordinates") {
            coordinates = arr
        } else if let arr: [[Double]] = try? node.extract("coordinates") {
            coordinates = arr
        } else {
            throw NodeError.unableToConvert(node: node, expected: "Geometry")
        }
        
        guard let geometry = Geometry.from(["type": type, "coordinates": coordinates]) else {
            throw NodeError.unableToConvert(node: node, expected: "Geometry")
        }
        
        self = geometry
    }
    
    public func makeNode(context: Context) throws -> Node {
        var node: Node = .object([
            ReqlType.key: .string(ReqlType.geometry.rawValue),
            "type": .string(self.name),
        ])
        
        if case .point = self, let coordinates = coordinates as? [Double] {
            node["coordinates"] = .array(coordinates.map({ .number(.double($0)) }))
        } else if let coordinates = coordinates as? [(Double, Double)] {
            node["coordinates"] = .array(coordinates.map { (x, y) in
                .array([.number(.double(x)), .number(.double(y))])
            })
        } else {
            node["coordinates"] = .array([])
        }
        
        return node
    }
}
