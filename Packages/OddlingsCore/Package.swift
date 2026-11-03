// swift-tools-version: 6.0
import PackageDescription

// Nur Foundation, damit `swift test` ohne Simulator und auch unter Linux läuft
// (Architekturregel 1). Die Plattformangaben gelten nur für Apple-Systeme.
let package = Package(
    name: "OddlingsCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "OddlingsCore", targets: ["OddlingsCore"]),
        // Balance-Labor (P2-6b): Prüfwerkzeug, nicht Teil der App.
        .executable(name: "oddlings-balance", targets: ["oddlings-balance"]),
    ],
    targets: [
        .target(
            name: "OddlingsCore",
            resources: [.copy("Resources/Balance"), .copy("Resources/Campaign")]
        ),
        .target(name: "OddlingsLab", dependencies: ["OddlingsCore"], resources: [.copy("Resources/labor.json")]),
        .executableTarget(name: "oddlings-balance", dependencies: ["OddlingsCore", "OddlingsLab"]),
        .testTarget(name: "OddlingsCoreTests", dependencies: ["OddlingsCore", "OddlingsLab"]),
    ]
)
