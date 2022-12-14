// swift-tools-version:5.7
import PackageDescription

var package = Package(
    name: "App", // do not rename
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", type: .dynamic, targets: ["App"]) ],
    dependencies: [
        .package(url: "https://github.com/fair-ground/Fair", from: "0.6.0"), // must be first
        .package(url: "https://github.com/jectivex/JXPod", from: "0.2.0"),
        .package(url: "https://github.com/jectivex/JXSwiftUI", from: "0.0.1"),
        .package(url: "https://github.com/simonbs/Runestone", from: "0.2.10"),
        .package(url: "https://github.com/simonbs/TreeSitterLanguages", from: "0.1.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"), // required
            .product(name: "FairKit", package: "Fair"),
            .product(name: "JXPod", package: "JXPod"),
            .product(name: "JXSwiftUI", package: "JXSwiftUI"),

            // Runestone is a syntax-highlighting text editor for iOS; the macOS version is stubbed as a TextEditor
            .product(name: "Runestone", package: "Runestone", condition: .when(platforms: [.iOS])),
            .product(name: "TreeSitterJavaScriptRunestone", package: "TreeSitterLanguages", condition: .when(platforms: [.iOS])),
            .product(name: "TreeSitterJavaScriptQueries", package: "TreeSitterLanguages", condition: .when(platforms: [.iOS])),
            .product(name: "TreeSitterJavaScript", package: "TreeSitterLanguages", condition: .when(platforms: [.iOS])),
        ], resources: [
            .process("Resources"), // processed resources
        ], plugins: [
        ]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
