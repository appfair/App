// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", type: .dynamic, targets: ["App"]) ],
    dependencies: [
        .package(url: "https://github.com/fair-ground/Fair", from: "0.5.0"), // required
        .package(url: "https://github.com/Sita-Sings-the-Blues/Media.git", from: "0.0.1"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"),
            .product(name: "Media", package: "Media"),
        ], resources: [
            .process("Resources"),
            .copy("Bundle"),
            .copy("App.yml"),
        ],
        linkerSettings: [.linkedFramework("AVKit")]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
