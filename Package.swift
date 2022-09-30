// swift-tools-version:5.7
import PackageDescription

/// This package template is forked from [appfair/App](https://github.com/appfair/App/fork)
/// and provides support for building and distributing an [App Fair](https://appfair.net) app.
///
/// Additional source-only dependencies can be added, but the initial "FairApp" dependency must
/// remain unchanged in order for the package to be eligible for App Fair integration and distribution.
///
/// In order to set up a new App Fair project in a fresh fork, run:
/// ```
/// swift package --allow-writing-to-package-directory fairtool app
/// ```
let package = Package(
    name: "App", // do not rename
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", type: .dynamic, targets: ["App"]) ],
    dependencies: [
        .package(url: "https://github.com/fair-ground/Fair", from: "0.6.0"), // must be first
        .package(url: "https://github.com/jectivex/JackPot", branch: "HEAD"),
        .package(url: "https://github.com/tiqtiq/WeatherTiq", from: "0.0.1"),
        .package(url: "https://github.com/tiqtiq/LocationTiq", from: "0.0.1"),
        .package(url: "https://github.com/tiqtiq/GeoNamesCities15000", from: "0.0.1"),
        .package(url: "https://github.com/groue/GRDBQuery.git", from: "0.5.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"), // required
            .product(name: "FairKit", package: "Fair"), // optional enhancements
            .product(name: "JackPot", package: "JackPot"),
            .product(name: "LocationTiq", package: "LocationTiq"),
            .product(name: "GeoNamesCities15000", package: "GeoNamesCities15000"),
            .product(name: "WeatherTiq", package: "WeatherTiq"),
            .product(name: "GRDB", package: "GRDB.swift"),
            .product(name: "GRDBQuery", package: "GRDBQuery"),
        ], resources: [
            .process("Resources"), // processed resources
            .copy("App.yml"),
        ]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
