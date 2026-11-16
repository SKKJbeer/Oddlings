import OddlingsCore

/// Was die nächste Welle bringt (A-2, R2): je Gegnerart die Anzahl, in der
/// Reihenfolge ihres ersten Auftretens. Wer Flitzer oder Panzerbestien erst
/// sieht, wenn sie laufen, kann nicht planen (Säule 3).
///
/// Reine Rechnung aus der Missionsdatei; sie liest keinen Zustand und ändert
/// nichts, damit Knopf und Tests dieselbe Vorschau sehen.
struct WaveForecast: Equatable {
    struct Entry: Equatable {
        let kind: EnemyKind
        let count: Int
        /// Kam in keiner früheren Welle vor: Der Zettel markiert sie. In der
        /// ersten Welle ist nichts neu, sonst stünde dort an jedem Bild ein Zeichen.
        let isNew: Bool
    }

    /// Mehr Arten passen nicht auf den Zettel; in Region 1 hat keine Welle mehr.
    static let maxEntries = 3

    /// Welle, ab 0 gezählt, wie `GameState.waveIndex`.
    let wave: Int
    let entries: [Entry]

    /// nil, wenn es die Welle nicht gibt oder sie leer ist.
    init?(waves: [WaveConfig], index: Int) {
        guard waves.indices.contains(index) else { return nil }
        var seen: [EnemyKind] = []
        for wave in waves[..<index] {
            for group in wave.groups where !seen.contains(group.enemy) { seen.append(group.enemy) }
        }
        var kinds: [EnemyKind] = []
        var counts: [Int] = []
        for group in waves[index].groups where group.count > 0 {
            if let at = kinds.firstIndex(of: group.enemy) {
                counts[at] += group.count
            } else {
                kinds.append(group.enemy)
                counts.append(group.count)
            }
        }
        guard !kinds.isEmpty else { return nil }
        wave = index
        entries = zip(kinds, counts).prefix(Self.maxEntries).map {
            Entry(kind: $0.0, count: $0.1, isNew: index > 0 && !seen.contains($0.0))
        }
    }

    var hasNew: Bool { entries.contains(where: \.isNew) }
}
