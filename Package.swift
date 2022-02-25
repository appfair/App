// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", type: .dynamic, targets: ["App"]) ],
    dependencies: [
        // the Fair main branch must be the *first* dependency
        .package(name: "Fair", url: "https://fair-ground.org/Fair.git", .branch("main")),
        // additional GitHub-hosted dependencies can be added below
        .package(name: "AudioKit", url: "https://github.com/AudioKit/AudioKit.git", from: "5.3.1"),
    ],
    targets: [
        .target(name: "App", dependencies: [ 
            .product(name: "FairApp", package: "Fair"),
            .product(name: "AudioKit", package: "AudioKit"),
        ], 
        resources: [
            .process("Resources"), 
            .copy("Bundle"),
        ],
        linkerSettings: [
            .linkedFramework("AVKit"),
        ]),
        .testTarget(name: "AppTests", dependencies: [
            "App"
        ]),
    ]
)

