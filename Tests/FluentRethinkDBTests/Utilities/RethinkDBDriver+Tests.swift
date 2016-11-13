#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import XCTest
import FluentRethinkDB
import RethinkDB
import Fluent

let r = RethinkDB.r

extension RethinkDBDriver {
    static var host: String {
        let defaultHost = "localhost"
        guard let rawValue = getenv("RETHINKDB_HOST") else {
            return defaultHost
        }
        
        return String(utf8String: rawValue) ?? defaultHost
    }
    
    static func makeTestConnection() -> RethinkDBDriver {
        do {
            let conn = try r.connect(host: self.host, db: "test")
            let driver = RethinkDBDriver(conn)
            return driver
        } catch {
            print()
            print()
            print("⚠️ RethinkDB Not Configured ⚠️")
            print()
            print("Error: \(error)")
            print()
            print("You must configure RethinkDB to run with the following configuration: ")
            print("    user: 'admin'")
            print("    password: '' // (empty)")
            print("    host: '127.0.0.1' (or specify host with env var RETHINKDB_HOST)")
            print("    database: 'test'")
            print()
            print()
            
            XCTFail("Configure RethinkDB")
            fatalError("Configure RethinkDB")
        }
    }
}
