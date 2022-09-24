// swift-tools-version:5.7
import PackageDescription
import Darwin
import class Foundation.ProcessInfo

/// true when we are running from Xcode; false for a fair-ground release
let runningInXcode = ProcessInfo.processInfo.environment["__CFBundleIdentifier"] == "com.apple.dt.Xcode"

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
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"), // required
            .product(name: "FairExpo", package: "Fair"),
            .product(name: "FairKit", package: "Fair"),
        ], resources: [
            .process("Resources"), // processed resources
            .copy("App.yml"),
        ]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

