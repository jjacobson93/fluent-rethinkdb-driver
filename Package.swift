import PackageDescription

let package = Package(
    name: "FluentRethinkDB",
    dependencies: [
        .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 0, minor: 11),
        .Package(url: "https://github.com/jjacobson93/rethink-swift.git", majorVersion: 0, minor: 9)
    ]
)