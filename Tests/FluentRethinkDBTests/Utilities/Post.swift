import Foundation
import Fluent

final class Post: Entity {
    /**
     Turn the convertible into a node
     
     - throws: if convertible can not create a Node
     - returns: a node if possible
     */
    
    var exists: Bool = false
    
    var id: Fluent.Node?
    var title: String
    var text: String
    var postedAt: Date
    var comments: [String]
    
    init(id: Node?, title: String, text: String, comments: [String], postedAt: Date) {
        self.id = id
        self.title = title
        self.text = text
        self.comments = comments
        self.postedAt = postedAt
    }
    
    func makeNode(context:Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "title": title,
            "text": text,
            "comments": comments.makeNode(context: context),
            "postedAt": postedAt.makeNode(context: context)
        ])
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        title = try node.extract("title")
        text = try node.extract("text")
        comments = try node.extract("comments")
        postedAt = try node.extract("postedAt")
    }
    
    static func prepare(_ database: Fluent.Database) throws {
        try database.create(entity) { _ in }
    }
    static func revert(_ database: Fluent.Database) throws {
        try database.delete(entity)
    }
}
