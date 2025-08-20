// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AuthAPI",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    products: [
        .library(name: "AuthAPI", targets: ["AuthAPI"])
    ],
    targets: [
        .target(
            name: "AuthAPI",
            path: "Sources/AuthAPI",
            resources: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AuthAPITests",
            dependencies: ["AuthAPI"],
            path: "Tests/AuthAPITests"
        )
    ]
)


