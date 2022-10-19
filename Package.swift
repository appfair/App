// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "App", // do not rename
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", type: .dynamic, targets: ["App"]) ],
    dependencies: [
        .package(url: "https://github.com/fair-ground/Fair", from: "0.6.0"), // must be first
        .package(url: "https://github.com/jectivex/JackPot", from: "0.0.1"),
        .package(url: "https://github.com/sqlenclave/SQLPod", from: "0.0.1"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"), // required
            .product(name: "FairKit", package: "Fair"),
            .product(name: "JackPot", package: "JackPot"),
            .product(name: "SQLPod", package: "SQLPod"),
        ], resources: [
            .process("Resources"), // processed resources
        ], plugins: [
            //.plugin(name: "FairBuild", package: "Fair"),
        ]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

