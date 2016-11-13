import PackageDescription

let package = Package(
    name: "FluentRethinkDB",
    dependencies: [
        .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 1),
        .Package(url: "https://github.com/jjacobson93/RethinkDBSwift.git", majorVersion: 0)
    ]
)