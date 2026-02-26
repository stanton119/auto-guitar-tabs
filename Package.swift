// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AutoGuitarTabs",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AutoGuitarTabs", targets: ["AutoGuitarTabs"])
    ],
    targets: [
        .executableTarget(
            name: "AutoGuitarTabs",
            dependencies: [],
            path: "Sources/AutoGuitarTabs"
        ),
        .testTarget(
            name: "AutoGuitarTabsTests",
            dependencies: ["AutoGuitarTabs"],
            path: "Tests/AutoGuitarTabsTests"
        )
    ]
)
