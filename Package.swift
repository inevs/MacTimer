// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacTimer",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "MacTimer"),
        .testTarget(name: "MacTimerTests", dependencies: ["MacTimer"]),
    ]
)
