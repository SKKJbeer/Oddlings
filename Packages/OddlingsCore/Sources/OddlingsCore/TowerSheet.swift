import Foundation

/// Eine Kennzahl auf der Wertetafel eines Turms (D-130). Alle sind so
/// gerichtet, dass mehr besser ist; ein Minus beim Vergleich ist also immer
/// ein Preis, den der Spieler zahlt.
public enum TowerFigure: String, CaseIterable, Sendable {
    /// Schaden je Sekunde über alle Ziele eines Schusses (Salve) bzw. über die
    /// volle Kette (Blitzturm). Die Zahl, an der man Türme vergleicht.
    case damagePerSecond
    /// Schaden des ersten Treffers.
    case damage
    /// Schüsse bzw. Pulse je Sekunde.
    case rate
    /// Reichweite in Feldern.
    case range
    /// Ziele je Schuss (Salve).
    case targets
    /// Ziele einer vollen Kette: erster Treffer plus Sprünge.
    case chainTargets
    /// Anteil, um den der Puls das Tempo eines Gegners senkt (0,5 = halb so schnell).
    case slow
    /// Sekunden, die eine Verlangsamung hält.
    case slowDuration
    /// Zusätzlicher Schaden, den verlangsamte Gegner von allen Türmen nehmen (Fäulnis).
    case vulnerable
}

public struct TowerReading: Equatable, Sendable {
    public var figure: TowerFigure
    public var value: Double

    public init(figure: TowerFigure, value: Double) {
        self.figure = figure
        self.value = value
    }
}

/// Die Werte eines Turms, wie sie die Tafel am Turm zeigt (D-130). Rechnet nur
/// aus `TowerConfig`, also aus `BalanceConfig.stats(of:)`: Volk, Ausrüstung,
/// Stufe und Spezialisierung stecken dort schon drin. Keine eigene Zahl.
public struct TowerSheet: Equatable, Sendable {
    /// In der Reihenfolge der Tafel; die erste ist die Leitzahl.
    public let readings: [TowerReading]

    public init(kind: TowerKind, stats: TowerConfig) {
        let rate = stats.attackInterval > 0 ? 1 / stats.attackInterval : 0
        var list: [TowerReading] = []
        func add(_ figure: TowerFigure, _ value: Double?) {
            if let value { list.append(TowerReading(figure: figure, value: value)) }
        }
        switch kind {
        case .bank:
            break
        case .watch:
            let targets = Double(max(1, stats.targets ?? 1))
            add(.damagePerSecond, stats.damage * targets * rate)
            add(.damage, stats.damage)
            add(.rate, rate)
            add(.range, stats.range)
            if targets > 1 { add(.targets, targets) }
        case .lightning:
            let jumps = max(0, stats.chainJumps ?? 0)
            let falloff = stats.chainFalloff ?? 1
            // Volle Kette ohne Gewitterkrone: jeder Sprung um `falloff` schwächer.
            // Mit Gewitterkrone auf verlangsamten Zielen wäre es mehr; die Tafel
            // nennt die sichere Untergrenze.
            var chain = 0.0, hit = stats.damage
            for _ in 0...jumps {
                chain += hit
                hit *= falloff
            }
            add(.damagePerSecond, chain * rate)
            add(.damage, stats.damage)
            add(.chainTargets, Double(jumps + 1))
            add(.range, stats.range)
        case .spore:
            add(.slow, stats.slowFactor.map { 1 - $0 })
            add(.range, stats.range)
            add(.slowDuration, stats.slowDuration)
            add(.rate, rate)
            add(.vulnerable, stats.vulnerableFactor.map { $0 - 1 })
        }
        readings = list
    }

    public func value(_ figure: TowerFigure) -> Double? {
        readings.first { $0.figure == figure }?.value
    }

    /// Jede Kennzahl beider Tafeln in der Reihenfolge der neuen, danach, was
    /// nur die alte hatte. Eine Kennzahl, die neu dazukommt (Salve: Ziele),
    /// hat vorher den Wert, den der Turm ohne sie hatte, wo es einen gibt.
    public func changes(to next: TowerSheet) -> [TowerChange] {
        var figures = next.readings.map(\.figure)
        for reading in readings where !figures.contains(reading.figure) { figures.append(reading.figure) }
        return figures.map { figure in
            TowerChange(figure: figure, before: value(figure) ?? Self.implicit(figure),
                        after: next.value(figure) ?? Self.implicit(figure))
        }
    }

    /// Was eine fehlende Kennzahl bedeutet: ein Ziel je Schuss, kein Zusatzschaden.
    private static func implicit(_ figure: TowerFigure) -> Double? {
        switch figure {
        case .targets: 1
        case .vulnerable: 0
        default: nil
        }
    }
}

/// Eine Zeile des Vorher-nachher-Vergleichs beim Aufwerten (D-130).
public struct TowerChange: Equatable, Sendable {
    public var figure: TowerFigure
    public var before: Double?
    public var after: Double?

    public init(figure: TowerFigure, before: Double?, after: Double?) {
        self.figure = figure
        self.before = before
        self.after = after
    }

    /// Gleich bis auf Rundungsrauschen der Faktoren (1,15 × 2,2 …).
    public var isUnchanged: Bool {
        guard let before, let after else { return false }
        return abs(after - before) <= 1e-9 * max(1, abs(before))
    }

    /// Relative Änderung, 0,5 für +50 %; nil ohne Ausgangswert oder bei null.
    public var ratio: Double? {
        guard let before, let after, before != 0 else { return nil }
        return after / before - 1
    }

    public var difference: Double? {
        guard let before, let after else { return nil }
        return after - before
    }
}
