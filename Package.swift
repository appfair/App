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
        .package(name: "Media", url: "https://github.com/Sita-Sings-the-Blues/Media.git", .upToNextMajor(from: "0.0.11")),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"),
            "Media",
        ], resources: [.process("Resources"), .copy("Bundle")],
        linkerSettings: [.linkedFramework("AVKit")]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
