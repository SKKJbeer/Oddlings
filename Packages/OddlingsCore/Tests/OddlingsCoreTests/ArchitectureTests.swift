import Foundation
import Testing

/// Architekturregeln 1 und 6 als Test statt als Vorsatz: Ein `import SpriteKit`
/// übersetzt auf dem Mac klaglos und fällt erst auf, wenn die Simulation nicht
/// mehr ohne Darstellung läuft.
@Suite("Architektur")
struct ArchitectureTests {
    static let sources: [URL] = {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/OddlingsCore")
        let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" } ?? []
        return files.sorted { $0.path < $1.path }
    }()

    @Test("Es gibt Quelldateien zu prüfen")
    func sourcesFound() { #expect(!Self.sources.isEmpty) }

    @Test("Simulation importiert nur Foundation")
    func onlyFoundation() throws {
        for file in Self.sources {
            for line in try String(contentsOf: file, encoding: .utf8).split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("import ") else { continue }
                #expect(trimmed == "import Foundation", "\(file.lastPathComponent): \(trimmed)")
            }
        }
    }

    @Test("Kein Date() und kein globaler Zufall in der Simulation")
    func noClockNoGlobalRandom() throws {
        let forbidden = ["Date()", ".random(", "SystemRandomNumberGenerator", "arc4random"]
        for file in Self.sources {
            let text = try String(contentsOf: file, encoding: .utf8)
            for word in forbidden {
                #expect(!text.contains(word), "\(file.lastPathComponent) enthält \(word)")
            }
        }
    }
}
