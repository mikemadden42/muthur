// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "muthur",
    platforms: [.macOS(.v14)], // Required for SwiftUI
    targets: [
        .executableTarget(
            name: "muthur",
            path: "Sources"
        ),
    ]
)
