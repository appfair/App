// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", targets: ["App"]) ],
    dependencies: [
        // the Fair main branch must be the *first* dependency
        .package(name: "Fair", url: "https://github.com/fair-ground/Fair.git", .branch("main")),
        .package(name: "AudioKit", url: "https://github.com/AudioKit/AudioKit.git", from: "5.2.2"),
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

