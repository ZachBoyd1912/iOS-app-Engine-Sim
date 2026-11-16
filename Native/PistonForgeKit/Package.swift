// swift-tools-version: 6.0
// PistonForgeKit: the game simulation, pure Swift with no UIKit, SwiftUI or RealityKit, so
// its tests run with `swift test` on a Linux CI runner as well as on a Mac.
import PackageDescription

let package = Package(
    name: "PistonForgeKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "PistonForgeKit", targets: ["PistonForgeKit"]),
    ],
    targets: [
        .target(name: "PistonForgeKit"),
        .testTarget(
            name: "PistonForgeKitTests",
            dependencies: ["PistonForgeKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
