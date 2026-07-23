// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Nagara",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", "0.9.0"..<"1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Nagara",
            path: "Sources/Nagara",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "NagaraTests",
            dependencies: ["Nagara", .product(name: "Testing", package: "swift-testing")],
            path: "Tests/NagaraTests"
        ),
    ]
)
