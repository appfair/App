// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", type: .dynamic, targets: ["App"]) ],
    dependencies: [
        // the Fair main branch must be the first dependency
        .package(name: "Fair", url: "https://fair-ground.org/Fair.git", .branch("main")),
        // additional hosted dependencies can be added below
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair"),
        ], resources: [.process("Resources"), .copy("Bundle")]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

// MARK: fair-ground package validation

// The following validations are required in order for 
// the package to be integrated by the fair-ground integrate-release process.
//
// These lines can be removed from your project, but the
// rules will be enforced during the `integrate` phase regardless.

precondition(package.name == "App", "Package.swift name must be 'App', but was: '\(package.name)'")
precondition(!package.dependencies.isEmpty, "Package.swift must have at least one dependency")
precondition(package.dependencies[0].name == "Fair", "first dependency name must be 'Fair', but was: '\(package.dependencies[0].name ?? "")'")
precondition(package.dependencies[0].url == "https://fair-ground.org/Fair.git", "first Package.swift dependency must be 'https://fair-ground.org/Fair.git', but was: '\(String(describing: package.dependencies[0].url))'")

precondition(package.products.count == 1, "Package.swift must have exactly one product")
precondition(package.products[0].name == "App", "Package.swift product must be named 'App', but was: '\(package.products[0].name)'")

// validate target names and source paths

precondition(package.targets.count == 2, "package must have exactly two targets named 'App' and 'AppTests'")
precondition(package.targets[0].name == "App", "first target must be named 'App', but was: '\(package.targets[0].name)'")
precondition(package.targets[0].path == nil || package.targets[0].path == "Sources", "first target path must be named 'Sources', but was: '\(package.targets[0].path ?? "")'")
precondition(package.targets[0].sources == nil, "first target sources must be empty")

precondition(package.targets[1].name == "AppTests", "second target must be named 'AppTests', but was: \(package.targets[1].name)")
precondition(package.targets[1].path == nil || package.targets[1].path == "Tests", "second target must be named 'Tests', but was: '\(package.targets[1].path ?? "")'")
precondition(package.targets[1].sources == nil, "second target sources must be empty")

precondition(!package.targets[0].dependencies.isEmpty, "package target must have at least one dependency")

// Target.Depencency is opaque and non-equatable, so resort to using the description for validation
precondition(String(describing: package.targets[0].dependencies[0]) == "productItem(name: \"FairApp\", package: Optional(\"Fair\"), condition: nil)", "first package dependency must be FairApp")
precondition(String(describing: package.platforms?.first) == "Optional(PackageDescription.SupportedPlatform(platform: PackageDescription.Platform(name: \"macos\"), version: Optional(\"12.0\")))", "package must support macOS 12")
precondition(String(describing: package.platforms?.last) == "Optional(PackageDescription.SupportedPlatform(platform: PackageDescription.Platform(name: \"ios\"), version: Optional(\"15.0\")))", "package must support iOS 15")


