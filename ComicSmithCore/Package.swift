// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ComicSmithCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "ComicSmithCore", targets: ["ComicSmithCore"])
    ],
    targets: [
        .target(
            name: "ComicSmithCore",
            path: "Sources/ComicSmithCore"
        ),
        .testTarget(
            name: "ComicSmithCoreTests",
            dependencies: ["ComicSmithCore"],
            path: "Tests/ComicSmithCoreTests"
        )
    ]
)
