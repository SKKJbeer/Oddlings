#if DEBUG
import Foundation

/// Leistungsprobe für den CI-Probelauf (`--fx-messung`, nur Debug-Bau): misst
/// nach dem Anlaufen 20 Sekunden lang die Bildzeiten und schreibt Mittelwert
/// und längstes Bild nach `Documents/fx-messung.json`. Die CI liest die Datei
/// aus dem Simulator (ci.yml, „Probelauf im Simulator").
@MainActor
final class FxProbe {
    static let argument = "--fx-messung"
    static let fileName = "fx-messung.json"
    /// Laden der Texturen und erste Bilder zählen nicht mit.
    private static let warmup: Double = 3
    private static let window: Double = 20

    private var elapsed: Double = 0
    private var stats = FrameStats()
    private(set) var written = false

    static func fromArguments() -> FxProbe? {
        ProcessInfo.processInfo.arguments.contains(argument) ? FxProbe() : nil
    }

    func add(_ frameTime: Double) {
        guard !written, frameTime > 0 else { return }
        elapsed += frameTime
        guard elapsed > Self.warmup else { return }
        stats.add(frameTime)
        if elapsed >= Self.warmup + Self.window { write() }
    }

    private func write() {
        written = true
        let result: [String: Double] = [
            "averageFPS": stats.averageFPS,
            "worstFrameMS": stats.worstMS,
            "frames": Double(stats.frames),
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]),
              let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        try? data.write(to: folder.appendingPathComponent(Self.fileName))
    }
}
#endif
