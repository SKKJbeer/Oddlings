import Foundation

/// Effektbudget je Bereich (A-5 Teil 2, D-181): Wo sich schon genug große
/// Wolken überlappen, spielt eine neue gedämpft statt voll. Die bestehende
/// Grenze `FxStyle.maxSprites` zählt nur die Menge im ganzen Bild; verdeckt
/// werden Gegner aber dort, wo sich Wolken stapeln (Review R1).
///
/// Rein und ohne SpriteKit, damit die Regel ohne Szene prüfbar ist. Läuft auf
/// der Uhr des `FxDirector` (D-050), Längen in Feldern.
struct FxAreaBudget: Equatable {
    /// Wie eine neue Wolke spielen darf.
    enum Grant: Equatable {
        case full
        /// Weniger Teilchen und blasser: `share` der Teilchen, `alpha` der Deckkraft.
        case damped(share: Double, alpha: Double)
    }

    private struct Claim: Equatable {
        let x: Double, y: Double, radius: Double, until: Double
    }

    /// Höchstens so viele Wolken dürfen sich voll überlappen.
    let limit: Int
    let dampedShare: Double
    let dampedAlpha: Double
    private var claims: [Claim] = []

    init(limit: Int, dampedShare: Double, dampedAlpha: Double) {
        self.limit = limit
        self.dampedShare = dampedShare
        self.dampedAlpha = dampedAlpha
    }

    /// Laufende Wolken zur Zeit `now`.
    func active(at now: Double) -> Int { claims.filter { $0.until > now }.count }

    /// Meldet eine Wolke an und sagt, wie sie spielen darf. Gedämpfte Wolken
    /// zählen mit: Auch sie decken etwas, und sonst käme die nächste wieder voll.
    mutating func claim(x: Double, y: Double, radius: Double, now: Double, life: Double) -> Grant {
        claims.removeAll { $0.until <= now }
        let overlapping = claims.filter { other in
            hypot(other.x - x, other.y - y) < other.radius + radius
        }.count
        claims.append(Claim(x: x, y: y, radius: radius, until: now + max(0, life)))
        return overlapping < limit ? .full : .damped(share: dampedShare, alpha: dampedAlpha)
    }

    mutating func reset() { claims = [] }
}

extension FxAreaBudget.Grant {
    /// Wie viele von `count` Teilchen kommen; mindestens eines, damit man sieht, dass etwas geschah.
    func count(_ count: Int) -> Int {
        switch self {
        case .full: count
        case .damped(let share, _): max(1, Int((Double(count) * share).rounded()))
        }
    }

    var alpha: Double {
        switch self {
        case .full: 1
        case .damped(_, let alpha): alpha
        }
    }
}
