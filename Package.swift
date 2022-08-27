// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", type: .dynamic, targets: ["App"]) ],
    dependencies: [
        .package(url: "https://github.com/fair-ground/Fair", from: "0.5.0"), // required
        .package(name: "AudioKit", url: "https://github.com/AudioKit/AudioKit.git", from: "5.4.1"),
    ],
    targets: [
        .target(name: "App", dependencies: [ 
            .product(name: "FairApp", package: "Fair"),
            .product(name: "FairKit", package: "Fair"),
            .product(name: "AudioKit", package: "AudioKit"),
        ], 
        resources: [
            .process("Resources"),
            .copy("Bundle"),
            .copy("App.yml"),
        ],
        linkerSettings: [
            .linkedFramework("AVKit"),
        ]),
        .testTarget(name: "AppTests", dependencies: [
            "App"
        ]),
    ]
)

// MARK: fair-ground package validation

// The following validations are required in order for the package
// to be accepted by the appfair's integration-release workflow.
//
// These lines can be removed from your project, but the
// rules will be enforced during the `integrate` phase regardless.

precondition(package.name == "App", "Package.swift name must be 'App', but was: '\(package.name)'")
precondition(!package.dependencies.isEmpty, "Package.swift must have at least one dependency")
precondition(package.dependencies.first?.url == "https://github.com/fair-ground/Fair", "first Package.swift dependency must be 'https://github.com/fair-ground/Fair', but was: '\(String(describing: package.dependencies.first?.url ?? ""))'")

precondition(package.products.count == 1, "Package.swift must have exactly one product")
precondition(package.products.first?.name == "App", "Package.swift product must be named 'App', but was: '\(package.products.first?.name ?? "")'")

// validate target names and source paths

precondition(package.targets.count == 2, "package must have exactly two targets named 'App' and 'AppTests'")

precondition(package.targets.first?.name == "App", "first target must be named 'App', but was: '\(package.targets.first?.name ?? "")'")
precondition(package.targets.first?.path == nil || package.targets.first?.path == "Sources", "first target path must be named 'Sources', but was: '\(package.targets.first?.path ?? "")'")
precondition(package.targets.first?.sources == nil, "first target sources must be empty")

precondition(package.targets.last?.name == "AppTests", "second target must be named 'AppTests', but was: \(package.targets.last?.name ?? "")")
precondition(package.targets.last?.path == nil || package.targets.last?.path == "Tests", "second target must be named 'Tests', but was: '\(package.targets.last?.path ?? "")'")
precondition(package.targets.last?.sources == nil, "second target sources must be empty")

precondition(package.targets.first?.dependencies.isEmpty == false, "package target must have at least one dependency")

// Target.Depencency is opaque and non-equatable, so resort to using the description for validation
precondition(String(describing: package.targets.first!.dependencies.first!).hasPrefix("productItem(name: \"FairApp\", package: Optional(\"Fair\")") == true, "first package dependency must be FairApp")


