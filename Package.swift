// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "App", // do not rename
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", type: .dynamic, targets: ["App"]) ],
    dependencies: [
        .package(url: "https://github.com/fair-ground/Fair", from: "0.6.0"), // must be first
        .package(url: "https://github.com/jectivex/JackPot", branch: "HEAD"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"), // required
            .product(name: "FairKit", package: "Fair"),
            .product(name: "JackPot", package: "JackPot"),
        ], resources: [
            .process("Resources"), // processed resources
            .copy("App.yml"),
        ]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

