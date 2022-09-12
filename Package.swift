// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", type: .dynamic, targets: ["App"]) ],
    dependencies: [
        .package(url: "https://github.com/fair-ground/Fair", from: "0.5.0"), // required
        .package(url: "https://github.com/jectivex/Jack", branch: "HEAD"),
        .package(url: "https://github.com/tiqtiq/WeatherTiq", branch: "HEAD"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"), // required
            .product(name: "FairKit", package: "Fair"),
            .product(name: "Jack", package: "Jack"),
            .product(name: "WeatherTiq", package: "WeatherTiq"),
        ], resources: [
            .process("Resources"),
            .copy("Bundle"),
            .copy("App.yml"),
        ]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
