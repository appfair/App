// swift-tools-version: 5.6
// compile and package the tool using:
// swift build -c release --arch arm64 --arch x86_64 && cat ./.build/apple/Products/Release/applaunchprivacy | base64 -o ../applaunchprivacy.b64
import PackageDescription
let package = Package(name: "applaunchprivacy", targets: [.executableTarget(name: "applaunchprivacy", path: ".", sources: ["main.swift"]) ])
