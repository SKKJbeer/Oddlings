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
        // Der Moorkönig (P3-4): langsam stampfend, schwer wankend, aufrecht.
        case .moorKing: Gait(stride: 0.62, hop: 0.02, squash: 0.10, sway: 0.09, lean: 0.01)
        // Moorhexe (D-143): schlurfend, gebeugt, wenig Hüpfen.
        case .witch: Gait(stride: 0.40, hop: 0.05, squash: 0.10, sway: 0.12, lean: 0.12)
        // Pilzbalg: watschelnd, rund, stark wiegend.
        case .puffball: Gait(stride: 0.38, hop: 0.06, squash: 0.22, sway: 0.16, lean: 0.02)
        // Sporling: klein und flink, hüpft.
        case .sporeling: Gait(stride: 0.30, hop: 0.14, squash: 0.20, sway: 0.06, lean: 0.12)
        }
    }

    /// Gangart mit Bildfolge (FX 02): Die Beine machen den Schritt, darum nur
    /// noch ein Rest an Hüpfen und Wiegen, sonst hüpft die Figur doppelt.
    static func framedGait(_ kind: EnemyKind) -> Gait {
        var gait = gait(kind)
        gait.stride = frameStride
        gait.hop *= 0.25
        gait.squash *= 0.3
        gait.sway *= 0.3
        gait.lean = 0
        return gait
    }

    /// Strecke je Schritt in der Bildfolge, in Feldern. Gemessen an der
    /// gerenderten Figur: Schrittweite des Beins bei 0,9 Feldern Größe.
    static let frameStride: Double = 0.24
    /// Dauer der Treffer- und der Sturzfolge.
    static let hitFramesLife: TimeInterval = 0.24
    static let deathFramesLife: TimeInterval = 0.5

    static let shadowAlpha: CGFloat = 0.45
    /// Blickrichtung links oder rechts erst ab diesem waagerechten Anteil der
    /// Laufrichtung (Tangente von `PathView`); darunter bleibt die letzte Seite.
    static let facingThreshold: Double = 0.03

    // MARK: Laufen (A-1, docs/konzepte/a-1-laufen.md)

    /// Radius des Bogens an jeder Wegecke, in Feldern: die halbe Wegbreite, mit
    /// der das Wegwerkzeug die Ecken der gemalten Kampfplätze rundet.
    static let pathCornerRadius: Double = 0.5
    /// Halbe Breite der Spur je Art. Der Weg ist ein Feld breit; 0,18 lässt
    /// Plünderer und Flitzer sichtbar nebeneinander laufen und bleibt auf dem
    /// Sand. Die Panzerbestie ist breit, der Boss läuft in der Mitte.
    static func laneWidth(_ kind: EnemyKind) -> Double {
        switch kind {
        case .raider, .runner, .witch, .sporeling: 0.18
        case .brute, .puffball: 0.08
        case .moorKing: 0
        }
    }
    /// Bis zu diesem Winkel zur Waagerechten zeigt eine Figur die Seitenansicht
    /// (35°, Konzept aaa-bewegung-und-bauen.md); steiler vorn oder hinten.
    static let sideAngle: Double = 35 * Double.pi / 180
    /// Überblenden beim Wechsel der Bildfolge, statt hart zu springen.
    static let viewBlend: TimeInterval = 0.12
    /// Neigung in die Kurve, im Bogenmaß je Krümmung (1/Felder). Bei 0,5 Feldern
    /// Radius ist die Krümmung 2: Flitzer 7°, Plünderer 3°, Panzerbestie 1°.
    static func bankLean(_ kind: EnemyKind) -> Double {
        switch kind {
        case .runner, .sporeling: 0.06
        case .raider: 0.03
        case .witch: 0.02
        case .brute, .puffball: 0.01
        case .moorKing: 0.005
        }
    }
    /// Wie schnell die Neigung ihrem Ziel folgt (je Sekunde): Sie kippt nicht
    /// in einem Bild, wenn die Figur in den Bogen läuft.
    static let bankRate: Double = 12
    /// Anlaufen nach dem Erscheinen: so lange und so viel zusätzliche Vorneigung,
    /// abklingend. Nur Bild, die Regel lässt den Gegner sofort mit voller Geschwindigkeit laufen.
    static let startupLife: TimeInterval = 0.4
    static let startupLean: Double = 0.18
    /// Schatten beim Aufsetzen so viel breiter (Anteil).
    static let contactWidth: CGFloat = 0.22
    /// Staub bei jedem n-ten Aufsetzen und seine Größe in Feldern. Flitzer
    /// trippeln oft und leicht, die Panzerbestie stampft selten und schwer.
    static func dustEvery(_ kind: EnemyKind) -> Int {
        switch kind {
        case .runner, .sporeling: 1
        case .raider, .moorKing, .witch: 2
        case .brute, .puffball: 3
        }
    }
    static func dustSize(_ kind: EnemyKind) -> Double {
        switch kind {
        case .sporeling: 0.12
        case .runner: 0.16
        case .raider, .witch: 0.2
        case .puffball: 0.28
        case .brute: 0.32
        case .moorKing: 0.4
        }
    }
    /// Höchstens so viele Staubwölkchen je Figur gleichzeitig.
    static let dustPerEnemy = 3
    static let footDustLife: TimeInterval = 0.4
    static let footDustAlpha: CGFloat = 0.55
    /// Zwei Gegner näher als so viele Felder gelten als deckungsgleich
    /// (Messung für Tests und Kontaktabzug, keine Regel).
    static let stackedDistance: CGFloat = 0.03
    /// Erst so lange zusammen gilt ein Paar als deckungsgleich: Beim Überholen
    /// berühren sich zwei Spuren kurz (gemessen höchstens 0,42 s in Region 1),
    /// das ist kein Gänsemarsch.
    static let stackedHold: TimeInterval = 0.5
    static let spawnLife: TimeInterval = 0.28
    static let hitLife: TimeInterval = 0.12
    /// Rückstoß beim Treffer, in Feldern.
    static let hitKnockback: CGFloat = 0.07
    static let hitFlashAlpha: CGFloat = 0.85
    /// Mindestabstand zwischen zwei Aufblitzen am selben Gegner
    /// (docs/art/rueckmeldung-je-ereignis.md, Grenzen).
    static let hitFlashGap: TimeInterval = 0.08
    /// Funke an der Panzerung (P2-10): höchstens einer je Gegner und halbe
    /// Sekunde, sonst knistert es bei Blitz und Sporen ununterbrochen.
    static let armorSparkGap: TimeInterval = 0.5
    static let armorSpark = SKColor(red: 0.92, green: 0.94, blue: 1.00, alpha: 1)
    static let slowTint = SKColor(red: 0.55, green: 0.95, blue: 0.45, alpha: 1)
    static let slowTintFactor: CGFloat = 0.35
    /// Wie schnell das helle Schadensstück im Lebensbalken nachläuft (Anteil je Sekunde).
    static let healthLagRate: Double = 1.4
    static let healthLag = SKColor(red: 1.00, green: 0.95, blue: 0.80, alpha: 1)

    // MARK: Boss (P3-4)

    /// Schildkuppel um den Moorkönig: Breite in Höhen der Figur, Farbe, Atmen.
    static let shieldWidth: CGFloat = 1.25
    static let shieldColor = SKColor(red: 0.55, green: 0.95, blue: 0.80, alpha: 1)
    static let shieldAlpha: CGFloat = 0.35
    static let shieldBreath: Double = 4
    /// Ruf: grüner Dunst an der Stelle des Königs.
    static let summonColor = SKColor(red: 0.45, green: 0.85, blue: 0.45, alpha: 1)
    static let summonSparks = 10
    /// Bildfolgen des Moorkönigs (FX 03): Schild heben bzw. senken, ein Ruf mit dem Stab.
    static let shieldFramesLife: TimeInterval = 0.45
    static let summonFramesLife: TimeInterval = 0.7

    static let deathLife: TimeInterval = 0.45
    static let deathSmoke = 6
    static let deathChunks = 8
    static let leakLife: TimeInterval = 0.35

    static func enemyColor(_ kind: EnemyKind) -> SKColor {
        switch kind {
        case .raider: SKColor(red: 0.45, green: 0.70, blue: 0.30, alpha: 1)
        case .runner: SKColor(red: 0.98, green: 0.55, blue: 0.20, alpha: 1)
        case .brute: SKColor(red: 0.55, green: 0.50, blue: 0.48, alpha: 1)
        case .moorKing: SKColor(red: 0.32, green: 0.45, blue: 0.30, alpha: 1)
        case .witch: SKColor(red: 0.45, green: 0.38, blue: 0.62, alpha: 1)
        case .puffball: SKColor(red: 0.80, green: 0.68, blue: 0.48, alpha: 1)
        case .sporeling: SKColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 1)
        }
    }

    // MARK: Heiler und Teiler (D-175, D-176)

    /// Heilung: Ring um die Hexe in Reichweite der Regel, Funken über jedem
    /// Geheilten. Höchstens ein Puls je Hexe und Sekunde, sonst flimmert eine
    /// Gruppe ununterbrochen.
    static let healColor = SKColor(red: 0.55, green: 1.00, blue: 0.60, alpha: 1)
    static let healRingLife: TimeInterval = 0.6
    static let healSparks = 3
    static let healGap: TimeInterval = 1.0
    /// Zerfall: Sporenwolke am Todesort.
    static let splitColor = SKColor(red: 0.90, green: 0.85, blue: 0.50, alpha: 1)
    static let splitPuffs = 6
    static let splitRingLife: TimeInterval = 0.45

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
    /// Das Glied in ein verlangsamtes Ziel ist dicker als ein normales (P2-8).
    static let comboGlowWidth: CGFloat = 0.5
    static let comboCoreWidth: CGFloat = 0.12
    static let comboRing: Double = 0.7
    static let comboPuffs = 6
    /// „Sporenfunke!“ und der Satz darunter, Schrift in Feldern.
    static let calloutSize: CGFloat = 0.55
    static let sentenceSize: CGFloat = 0.34
    static let calloutLife: TimeInterval = 1.2
    static let sentenceLife: TimeInterval = 3.6
    /// Sporenschimmer unter verlangsamten Gegnern: Breite in Gegnerhöhen, Atmen je Sekunde.
    static let slowAuraWidth: CGFloat = 1.25
    static let slowAuraAlpha: CGFloat = 0.55
    static let slowAuraBreath: Double = 5

    // MARK: Einstieg (P2-8)

    /// Hand des Einstiegs: Breite und Hub in Feldern, eine Tippbewegung je Periode.
    static let handSize: CGFloat = 0.95
    static let handLift: CGFloat = 0.45
    static let guideRipple: CGFloat = 1.3
    static let guidePeriod: TimeInterval = 1.3
    static let guideColor = SKColor(red: 1.00, green: 0.95, blue: 0.70, alpha: 1)

    static let sporeLife: TimeInterval = 0.55
    static let sporePuffs = 12
    static let sporeColor = SKColor(red: 0.62, green: 0.92, blue: 0.40, alpha: 1)

    // MARK: Festungsfähigkeit (R-3, R-4)

    /// Steinregen: Schatten und Ring warnen bis zum Einschlag, Steine fallen
    /// so, dass sie zum Einschlag ankommen.
    static let strikeShadowAlpha: CGFloat = 0.55
    static let strikeRing = SKColor(red: 1.00, green: 0.55, blue: 0.25, alpha: 1)
    static let strikeStones = 7
    static let stoneFall: TimeInterval = 0.45
    static let stoneSize: CGFloat = 0.42
    static let stone = SKColor(red: 0.62, green: 0.58, blue: 0.54, alpha: 1)
    static let impactShards = 12
    static let impactDust = 12
    static let shakeImpact: Double = 0.65
    /// Mondmal: kühles Licht statt Steinen, kein Wackeln.
    static let moon = SKColor(red: 0.62, green: 0.70, blue: 1.00, alpha: 1)
    static let moonSparks = 16
    /// Betäubung: Sternchen über dem Kopf (Höhe und Radius in Gegnerhöhen).
    static let stunStars = 3
    static let stunStarSize: CGFloat = 0.2
    static let stunHeight: CGFloat = 1.25
    static let stunRadius: Double = 0.32
    static let stunSpin: Double = 7
    /// Bollwerk: wächst federnd aus dem Boden, versinkt am Ende.
    static let wallRise: TimeInterval = 0.32
    static let wallFall: TimeInterval = 0.35
    static let shakeWall: Double = 0.4

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
