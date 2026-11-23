#if DEBUG
import Foundation

/// Messung für den Kontaktabzug der CI (`--kontaktabzug`, nur Debug-Bau, D-145,
/// docs/konzepte/a-1-laufen.md). Die CI fotografiert jede Mission an festen
/// Zeiten; die App schreibt dazu, was sich am Bild prüfen lässt, nach
/// `Documents/kontaktabzug-<mission>.json`: höchste Zahl Gegner, Bilder mit zwei
/// fast deckungsgleichen Gegnern, größte Abweichung von der Regelposition in
/// Feldern, Eckbögen und Staub. Geschrieben wird laufend, damit die Datei auch
/// steht, wenn die CI die App vor dem Ende beendet.
@MainActor
final class ContactSheetProbe {
    static let argument = "--kontaktabzug"
    /// Höchstens so oft schreiben (Sekunden Effekt-Uhr): genug für die Bilder
    /// der CI, ohne jedes Bild auf die Platte zu gehen.
    private static let interval: Double = 1

    private let mission: String
    private var elapsed: Double = 0
    private var nextWrite: Double = 0
    private(set) var frames = 0
    private(set) var maxEnemies = 0
    private(set) var maxDeviation: Double = 0
    /// Bilder mit mindestens einem Gegner unter einer Wolke über ihm, und die
    /// höchste Zahl solcher Gegner in einem Bild (D-184).
    private(set) var occludedFrames = 0
    private(set) var maxOccluded = 0

    init(mission: String) { self.mission = mission }

    static func fromArguments(mission: String) -> ContactSheetProbe? {
        ProcessInfo.processInfo.arguments.contains(argument) ? ContactSheetProbe(mission: mission) : nil
    }

    func add(_ frameTime: Double, enemies: Int, deviation: Double, stacked: Int, stats: FxDirector.Stats,
             occluded: Int = 0) {
        guard frameTime > 0 else { return }
        elapsed += frameTime
        frames += 1
        if occluded > 0 { occludedFrames += 1 }
        maxOccluded = max(maxOccluded, occluded)
        maxEnemies = max(maxEnemies, enemies)
        maxDeviation = max(maxDeviation, deviation)
        guard elapsed >= nextWrite else { return }
        nextWrite = elapsed + Self.interval
        write(stacked: stacked, stats: stats)
    }

    private func write(stacked: Int, stats: FxDirector.Stats) {
        let result: [String: Any] = [
            "mission": mission,
            "seconds": elapsed,
            "frames": frames,
            "maxEnemies": maxEnemies,
            "stackedFrames": stacked,
            "maxDeviationFields": maxDeviation,
            "bends": stats.bends,
            "footfalls": stats.footfalls,
            "occludedFrames": occludedFrames,
            "maxOccluded": maxOccluded,
            "dampedClouds": stats.damped,
            "mergedGold": stats.merged,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]),
              let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        try? data.write(to: folder.appendingPathComponent("kontaktabzug-\(mission).json"))
    }
}
#endif
