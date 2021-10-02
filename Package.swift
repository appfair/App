// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [ .macOS(.v11), .iOS(.v14) ],
    products: [ .library(name: "App", targets: ["App"]) ],
    dependencies: [
        // the Fair main branch must be the first dependency to pass integration
        .package(name: "Fair", url: "https://fair-ground.org/Fair.git", .branch("main")),
        .package(name: "AudioKitUI", url: "https://github.com/AudioKit/AudioKitUI.git", .branch("main")),
    ],
    targets: [
        .target(name: "App", dependencies: [ 
            .product(name: "FairApp", package: "Fair"),
            .product(name: "AudioKitUI", package: "AudioKitUI"),
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

