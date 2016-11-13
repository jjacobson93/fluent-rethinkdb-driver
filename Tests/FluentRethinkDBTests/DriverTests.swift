import XCTest
@testable import FluentRethinkDB
@testable import Fluent

class DriverTests: XCTestCase {
    static var allTests: [(String, (DriverTests) -> () throws -> Void)] = [
        ("testSave", testSave),
        ("testFind", testFind),
        ("testUpdate", testUpdate),
        ("testDelete", testDelete)
    ]
    
    static var driver: RethinkDBDriver!
    static var database: Fluent.Database!
    
    override class func setUp() {
        self.driver = RethinkDBDriver.makeTestConnection()
        self.database = Database(self.driver)
        do {
            try Post.revert(self.database)
        } catch {
            // if this fails, it's most likely because the table doesn't exist
        }
        
        do {
            try Post.prepare(self.database)
            Post.database = self.database
        } catch {
            XCTFail("Could not create table: \(error)")
        }
    }
    
    func saveAndValidate(post: Post) -> Node {
        var p = post
        do {
            try p.save()
        } catch {
            XCTFail("Could not save: \(error)")
        }
        
        guard let id = p.id, id != .null else {
            XCTFail("ID was not returned")
            return .null
        }
        
        return id
    }
    
    func testSave() throws {
        var post = Post(id: nil, title: "Hello, world", text: "foobar")
        
        do {
            try post.save()
        } catch {
            XCTFail("Could not save: \(error)")
        }
    }
    
    func testFind() throws {
        let post = Post(id: nil, title: "Come find me!", text: "You probably can't")
        let id = self.saveAndValidate(post: post)
        
        do {
            let found = try Post.find(id)
            XCTAssertNotNil(found)
            XCTAssertEqual(post.title, found!.title)
            XCTAssertEqual(post.text, found!.text)
        } catch {
            XCTFail("Could not fetch post: \(error)")
        }
    }
    
    func testUpdate() throws {
        let badText = "We all mkae tpyos stomtiems"
        let goodText = "We all make typos sometimes"
        
        var post = Post(id: nil, title: "Typos", text: badText)
        
        let id = self.saveAndValidate(post: post)
    
        do {
            let found = try Post.find(id)
            XCTAssertNotNil(found)
            XCTAssertEqual(post.title, found!.title)
            XCTAssertEqual(post.text, found!.text)
        } catch {
            XCTFail("Could not fetch post: \(error)")
        }
        
        do {
            post.text = goodText
            try post.save()
        } catch {
            XCTFail("Could not save: \(error)")
        }
        
        do {
            let found = try Post.find(id)
            XCTAssertNotNil(found)
            XCTAssertEqual(post.title, found!.title)
            XCTAssertEqual(post.text, found!.text)
        } catch {
            XCTFail("Could not fetch post: \(error)")
        }
    }
    
    func testDelete() throws {
        let post = Post(id: nil, title: "Get rid of me", text: "(x _ x)")
        let id = self.saveAndValidate(post: post)
        
        do {
            try post.delete()
        } catch {
            XCTFail("Could not delete post: \(error)")
        }
        
        do {
            let found = try Post.find(id)
            XCTAssertNil(found)
        } catch {
            XCTFail("Post was not deleted: \(error)")
        }
    }
}
