// swift-tools-version: 5.9
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
