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
        .package(url: "https://github.com/jectivex/Jack", from: "2.1.0"),
        //.package(url: "https://github.com/jectivex/JackPot", from: "0.1.2"),
        .package(url: "https://github.com/sqlenclave/SQLEnclave", from: "0.0.1"),
        .package(url: "https://github.com/tiqtiq/WeatherTiq", from: "0.0.1"),
        .package(url: "https://github.com/tiqtiq/LocationTiq", from: "0.0.1"),
        .package(url: "https://github.com/tiqtiq/GeoNamesCities15000", from: "0.0.1"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "3.5.0"),
        //.package(url: "https://github.com/Cloud-Cuckoo/App.git", from: "0.8.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"), // required
            .product(name: "FairKit", package: "Fair"), // optional enhancements
            .product(name: "Jack", package: "Jack"),
            //.product(name: "JackPot", package: "JackPot"),
            .product(name: "SQLEnclave", package: "SQLEnclave"),
            .product(name: "LocationTiq", package: "LocationTiq"),
            .product(name: "GeoNamesCities15000", package: "GeoNamesCities15000"),
            .product(name: "WeatherTiq", package: "WeatherTiq"),
            .product(name: "Lottie", package: "lottie-ios"),
        ], resources: [
            .process("Resources"), // processed resources
        ], plugins: [
            //.plugin(name: "FairBuild", package: "Fair"),
        ]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
