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
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"), // required
            //.product(name: "FairKit", package: "Fair"), // optional enhancements
        ], resources: [
            .process("Resources"), // processed resources
        ], plugins: [
            //.plugin(name: "FairBuild", package: "Fair"),
        ]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

// MARK: fair-ground package validation

// The following validations are required in order for the package
// to be accepted by the appfair's integration-release workflow.
//
// These lines can be removed from your project, but the
// rules will be enforced during the `integrate` phase regardless.
protocol PDep { var url: String? { get } }
extension Package.Dependency : PDep { }

precondition(package.name == "App", "Package.swift name must be 'App', but was: '\(package.name)'")
precondition(!package.dependencies.isEmpty, "Package.swift must have at least one dependency")
precondition((package.dependencies[0] as PDep).url == "https://github.com/fair-ground/Fair", "first Package.swift dependency must be 'https://github.com/fair-ground/Fair")

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
precondition(String(describing: package.targets[0].dependencies[0]).hasPrefix("productItem(name: \"FairApp\", package: Optional(\"Fair\")") == true, "first package dependency must be FairApp")

