//
//  Regex.swift
//  FluentRethinkDB
//
//  Created by Jeremy Jacobson on 11/13/16.
//
//

import Foundation

struct Regex {
    // grr
    static func escapedPattern(for string: String) -> String {
        #if os(Linux)
            return RegularExpression.escapedPattern(for: string)
        #else
            return NSRegularExpression.escapedPattern(for: string)
        #endif
    }
}
