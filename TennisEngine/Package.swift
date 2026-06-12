// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TennisEngine",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TennisEngine", targets: ["TennisEngine"])
    ],
    targets: [
        .target(name: "TennisEngine"),
        .testTarget(name: "TennisEngineTests", dependencies: ["TennisEngine"])
    ]
)
