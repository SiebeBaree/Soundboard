// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Soundboard",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "Soundboard")
    ]
)
