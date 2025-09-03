// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ComicSmithDemoApp",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ComicSmithDemoApp", targets: ["ComicSmithDemoApp"])
    ],
    dependencies: [
        .package(path: "../ComicSmithCore") // Adjust path after unzipping next to ComicSmithCore
    ],
    targets: [
        .executableTarget(
            name: "ComicSmithDemoApp",
            dependencies: ["ComicSmithCore"],
            path: "Sources/ComicSmithDemoApp"
        )
    ]
)
