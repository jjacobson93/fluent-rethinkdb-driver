//
//  RethinkDBDriver.swift
//  FluentRethinkDB
//
//  Created by Jeremy Jacobson on 9/8/16.
//  Copyright © 2016 Jeremy Jacobson. All rights reserved.
//

import Foundation
import Fluent
import Node
import RethinkDB

let r = RethinkDB.r

public class RethinkDBDriver: Fluent.Driver {
    public var idKey: String = "id"

    public let connection: Connection

    public enum DriverError: Error {
        case unsupported(String)
        case rethinkError(String)
    }
    
    public init(_ connection: Connection) {
        self.connection = connection
    }

    public func query<T: Entity>(_ query: Fluent.Query<T>) throws -> Node {
        let conn = self.connection
        var result: Any = Node.null
        switch query.action {
        case .create, .modify, .delete:
            let reql: ReqlExpr
            if case .create = query.action {
                reql = try self.create(query)
            } else if case .modify = query.action {
                reql = try self.modify(query)
            } else {
                reql = try self.delete(query)
            }
            
            let writeResult: WriteResult = try reql.run(conn)
            if query.action == .create, let id = writeResult.generatedKeys.first {
                return .string(id)
            }
            
            guard let first = writeResult.changes.first else {
                return .array([])
            }
            
            if query.action == .delete {
                result = [first.oldValue]
            }
            
            if query.action == .modify {
                result = [first.newValue]
            }
        case .fetch:
            let reql = try self.fetch(query)
            let cursor: Cursor<Document> = try reql.run(conn)
            result = cursor.toArray()
        }
        
        return self.anyToNode(result)
    }

    public func schema(_ schema: Fluent.Schema) throws {
        let conn = self.connection
        switch schema {
        case .create(let table, _):
            // we ignore the fields here because RethinkDB tables are schema-less
            let _: WriteResult = try r.tableCreate(table).run(conn)
            // wait until the table is ready, otherwise someone might try to access it
            let _: Document = try r.table(table).wait().run(conn)
        case .delete(let table):
            let _: WriteResult = try r.tableDrop(table).run(conn)
        default:
            break
        }
    }

    public func raw(_ raw: String, _ values: [Node]) throws -> Node {
        throw DriverError.unsupported("Raw queries are unsupported by RethinkDB")
    }

    /**
     * Helper functions
     */
    
    func create<T: Entity>(_ query: Fluent.Query<T>) throws -> ReqlExpr {
        // ignore id because we don't want the id to be inserted as null in the DB
        let doc = self.document(from: query, ignoreId: true)
        return r.table(query.entity).insert(doc)
    }

    func fetch<T: Entity>(_ query: Fluent.Query<T>) throws -> ReqlExpr {
        var reql = r.table(query.entity)
        if !query.unions.isEmpty {
            throw DriverError.unsupported("Unions are unsupported")
        }
        
        for filter in query.filters {
            reql = reql.filter { (e: ReqlExpr) -> ReqlExpr in
                return self.filter(filter, e)
            }
        }
        
        for sort in query.sorts {
            let dir = sort.direction == .ascending ? r.asc : r.desc
            reql = reql.orderBy(dir(sort.field))
        }
        
        if let limit = query.limit {
            reql = reql.skip(limit.offset).limit(limit.count)
        }
        
        return reql
    }
    
    func modify<T: Entity>(_ query: Fluent.Query<T>) throws -> ReqlExpr {
        let doc = self.document(from: query)
        return try self.fetch(query).update(doc, options: .returnChanges(true))
    }
    
    func delete<T: Entity>(_ query: Fluent.Query<T>) throws -> ReqlExpr {
        return try self.fetch(query).delete(.returnChanges(true))
    }
    
    func filter(_ filter: Fluent.Filter, _ reql: ReqlExpr) -> ReqlExpr {
        switch filter.method {
        case .compare(let field, let comparison, let value):
            let expr = reql[field]
            return self.compare(expr, comparison, value)
        case .subset(let field, let scope, let values):
            switch scope {
            case .in:
                return r.expr(values).contains(reql[field])
            case .notIn:
                return r.expr(values).contains(reql[field]).not()
            }
        case .group(let relation, let filters):
            switch relation {
            case .and:
                var expr = reql
                for filter in filters {
                    expr = expr.and(self.filter(filter, expr))
                }
                return expr
            case .or:
                var expr = reql
                for filter in filters {
                    expr = expr.or(self.filter(filter, expr))
                }
                return expr
            }
        }
    }
    
    func compare(_ expr: ReqlExpr, _ comparison: Fluent.Filter.Comparison, _ value: Node) -> ReqlExpr {
        switch comparison {
        case .contains:
            return expr.contains(value)
        case .equals:
            return expr == value
        case .notEquals:
            return expr != value
        case .greaterThan:
            return expr > value
        case .greaterThanOrEquals:
            return expr >= value
        case .lessThan:
            return expr < value
        case .lessThanOrEquals:
            return expr <= value
        case .hasPrefix:
            guard let str = value.string else {
                return expr
            }
            
            let escaped = Regex.escapedPattern(for: str)
            return expr.match("^" + escaped)
        case .hasSuffix:
            guard let str = value.string else {
                return expr
            }
            
            let escaped = Regex.escapedPattern(for: str)
            return expr.match(r.expr(escaped) + "$")
        }
    }
    
    func document<T: Entity>(from query: Fluent.Query<T>, ignoreId: Bool = false) -> Document {
        let data = query.data?.nodeObject ?? [:]
        var doc = [String: Any]()
        for (key, value) in data {
            if key == self.idKey && value == .null && ignoreId {
                continue
            }
            
            doc[key] = value.json
        }
        return Document(element: doc)
    }

    func anyToNode(_ a: Any) -> Node {
        if let num = a as? Number {
            switch num {
            case .double(let d): return .number(.double(d))
            case .float(let f): return .number(.double(Double(f)))
            case .int(let i): return .number(.int(Int(i)))
            case .uint(let u): return .number(.uint(UInt(u)))
            }
        }

        if let int = a as? Int {
            return .number(.int(int))
        }

        if let uint = a as? UInt {
            return .number(.uint(uint))
        }

        if let bool = a as? Bool {
            return .bool(bool)
        }

        if let str = a as? String {
            return .string(str)
        }

        if let double = a as? Double {
            return .number(.double(double))
        }

        if let arr = a as? [Any] {
            return .array(arr.map { self.anyToNode($0) })
        }

        if let dict = a as? [String: Any] {
            var d = [String: Node]()
            for key in dict.keys {
                d[key] = self.anyToNode(dict[key]!)
            }
            return .object(d)
        }
        
        if let doc = a as? Document {
            return self.anyToNode(doc.json)
        }

        if let bytes = a as? [UInt8] {
            return .bytes(bytes)
        }

        if let node = a as? Node {
            return node
        }

        return .null
    }
}
