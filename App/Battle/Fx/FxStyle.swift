import OddlingsCore
import SpriteKit

/// Alle Werte der Bewegung und der Effekte an einer Stelle. Spielwerte stehen
/// nie hier (Architekturregel 7); diese Zahlen bestimmen nur Aussehen und
/// Dauer. Längen in Feldern, Zeiten in Sekunden.
/// Eigene Datei neben `BattleStyle`, damit Effekte und Oberfläche getrennt
/// wachsen können (Abstimmung mit UI 01).
@MainActor
enum FxStyle {
    // MARK: Gegner

    /// Gangart je Gegner, nach den Konzeptblättern in docs/art/figuren.md.
    static func gait(_ kind: EnemyKind) -> Gait {
        switch kind {
        // Gleichmäßiges Hüpfen, leichtes Wiegen.
        case .raider: Gait(stride: 0.42, hop: 0.13, squash: 0.18, sway: 0.10, lean: 0.06)
        // Schnell und flach, stark vorgebeugt.
        case .runner: Gait(stride: 0.55, hop: 0.08, squash: 0.12, sway: 0.05, lean: 0.20)
        // Schwer: kaum Hüpfen, kräftiges Stauchen, Wanken.
        case .brute: Gait(stride: 0.50, hop: 0.04, squash: 0.14, sway: 0.07, lean: 0.03)
        }
    }

    static let shadowAlpha: CGFloat = 0.45
    /// Blickrichtung: so weit voraus auf dem Weg nachsehen, und erst ab
    /// diesem Versatz umdrehen (Felder).
    static let facingLookahead: Double = 0.15
    static let facingThreshold: Double = 0.03
    static let spawnLife: TimeInterval = 0.28
    static let hitLife: TimeInterval = 0.12
    /// Rückstoß beim Treffer, in Feldern.
    static let hitKnockback: CGFloat = 0.07
    static let hitFlashAlpha: CGFloat = 0.85
    /// Mindestabstand zwischen zwei Aufblitzen am selben Gegner
    /// (docs/art/rueckmeldung-je-ereignis.md, Grenzen).
    static let hitFlashGap: TimeInterval = 0.08
    static let slowTint = SKColor(red: 0.55, green: 0.95, blue: 0.45, alpha: 1)
    static let slowTintFactor: CGFloat = 0.35
    /// Wie schnell das helle Schadensstück im Lebensbalken nachläuft (Anteil je Sekunde).
    static let healthLagRate: Double = 1.4
    static let healthLag = SKColor(red: 1.00, green: 0.95, blue: 0.80, alpha: 1)

    static let deathLife: TimeInterval = 0.45
    static let deathSmoke = 6
    static let deathChunks = 8
    static let leakLife: TimeInterval = 0.35

    static func enemyColor(_ kind: EnemyKind) -> SKColor {
        switch kind {
        case .raider: SKColor(red: 0.45, green: 0.70, blue: 0.30, alpha: 1)
        case .runner: SKColor(red: 0.98, green: 0.55, blue: 0.20, alpha: 1)
        case .brute: SKColor(red: 0.55, green: 0.50, blue: 0.48, alpha: 1)
        }
    }

    // MARK: Türme

    static let buildLife: TimeInterval = 0.45
    /// Fallhöhe beim Bau.
    static let buildDrop: CGFloat = 1.1
    static let sellLife: TimeInterval = 0.40
    static let dustPuffs = 8
    static let dust = SKColor(red: 0.86, green: 0.78, blue: 0.62, alpha: 1)

    static let recoilLife: TimeInterval = 0.18
    static let breathPeriod: TimeInterval = 2.6
    static let breathAmount: CGFloat = 0.012
    /// Höhe des Kristalls über dem Fußpunkt beim Blitzturm, aus dem Bild gemessen.
    static let crystalHeight: CGFloat = 1.18
    static let crystalGlow = SKColor(red: 0.45, green: 0.70, blue: 1.00, alpha: 1)
    /// Wo Pfeil und Blitz den Turm verlassen.
    static let muzzleHeight: CGFloat = 0.95

    // MARK: Geschosse

    static let arrowSpeed: Double = 16
    static let arrowMinLife: Double = 0.06
    static let arrowMaxLife: Double = 0.16
    static let arrowArc: Double = 0.18
    static let arrowLength: CGFloat = 0.55
    static let arrowHitSparks = 5
    static let arrowSpark = SKColor(red: 1.00, green: 0.85, blue: 0.50, alpha: 1)

    static let boltLife: TimeInterval = 0.22
    static let boltLinkDelay: TimeInterval = 0.04
    static let boltSegments = 7
    static let boltJitter: Double = 0.16
    static let boltGlow = SKColor(red: 0.40, green: 0.65, blue: 1.00, alpha: 1)
    static let boltCore = SKColor(red: 0.92, green: 0.97, blue: 1.00, alpha: 1)
    static let boltGlowWidth: CGFloat = 0.32
    static let boltCoreWidth: CGFloat = 0.08
    static let boltSparks = 6
    /// Sporenfunke (Marktanalyse E2): Blitz trifft verlangsamtes Ziel.
    static let comboSparks = 14
    static let comboColor = SKColor(red: 0.45, green: 1.00, blue: 0.80, alpha: 1)

    static let sporeLife: TimeInterval = 0.55
    static let sporePuffs = 12
    static let sporeColor = SKColor(red: 0.62, green: 0.92, blue: 0.40, alpha: 1)

    // MARK: Gold, Text, Banner

    static let coinsPerKill = 3
    static let coinSize: CGFloat = 0.28
    static let coinLife: TimeInterval = 0.7
    static let gold = SKColor(red: 1.00, green: 0.84, blue: 0.25, alpha: 1)
    static let floatLife: TimeInterval = 0.8
    static let bannerIn: TimeInterval = 0.35
    static let bannerHold: TimeInterval = 1.0
    static let bannerOut: TimeInterval = 0.3
    static let confetti = 48
    static let confettiLife: TimeInterval = 1.6
    static let confettiColors: [SKColor] = [
        SKColor(red: 1.00, green: 0.84, blue: 0.25, alpha: 1),
        SKColor(red: 0.95, green: 0.35, blue: 0.30, alpha: 1),
        SKColor(red: 0.40, green: 0.70, blue: 1.00, alpha: 1),
        SKColor(red: 0.55, green: 0.90, blue: 0.40, alpha: 1),
    ]
    static let rejectLife: TimeInterval = 0.3
    static let reject = SKColor(red: 1.00, green: 0.25, blue: 0.20, alpha: 1)

    // MARK: Bildschirm

    /// Größter Ausschlag beim Wackeln, in Feldern.
    static let shakeAmplitude: Double = 0.18
    static let shakeDecay: Double = 2.2
    static let shakeLeak: Double = 0.55
    static let shakeBuild: Double = 0.30

    // MARK: Leistung

    /// Höchstzahl flüchtiger Sprites. Ab `optionalShare` davon entfallen
    /// Zierteilchen, damit Pfeil, Blitz und Münzen immer kommen.
    static let maxSprites = 360
    static let optionalShare = 0.7
    /// Rechenzeit je Bild, die `FxBudgetTests` im Mittel erlaubt (Simulator,
    /// Debug-Bau). 16,7 ms ist ein ganzes Bild bei 60 Hz; die Hälfte bleibt
    /// fürs Zeichnen.
    static let frameBudgetMS: Double = 8
}
