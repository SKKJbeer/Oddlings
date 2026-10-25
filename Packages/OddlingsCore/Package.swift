// swift-tools-version: 6.0
import PackageDescription

// Nur Foundation, damit `swift test` ohne Simulator und auch unter Linux läuft
// (Architekturregel 1). Die Plattformangaben gelten nur für Apple-Systeme.
let package = Package(
    name: "OddlingsCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "OddlingsCore", targets: ["OddlingsCore"]),
    ],
    targets: [
        .target(
            name: "OddlingsCore",
            resources: [.copy("Resources/Balance")]
        ),
        .testTarget(name: "OddlingsCoreTests", dependencies: ["OddlingsCore"]),
    ]
)
