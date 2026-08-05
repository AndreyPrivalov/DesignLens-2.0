// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignLens",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DesignLens",
            targets: ["DesignLens"]
        )
    ],
    targets: [
        .executableTarget(
            name: "DesignLens",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "DesignLensTests",
            dependencies: ["DesignLens"]
        )
    ]
)
