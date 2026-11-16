// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UsageAI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "UsageAI", targets: ["UsageAI"])
    ],
    targets: [
        .executableTarget(
            name: "UsageAI",
            path: "Sources/UsageAI"
        )
    ]
)
