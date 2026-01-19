// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MuthurSwiftUI",
    platforms: [.macOS(.v14)], // Required for SwiftUI
    targets: [
        .executableTarget(
            name: "MuthurSwiftUI",
            path: "Sources"
        ),
    ]
)
