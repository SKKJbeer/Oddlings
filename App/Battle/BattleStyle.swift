import OddlingsCore
import SpriteKit

/// Alle Darstellungswerte der Platzhaltergrafik an einer Stelle. Spielwerte
/// stehen nie hier, sondern in der Missionsdatei (Architekturregel 7); diese
/// Zahlen bestimmen nur Aussehen und Dauer von Effekten und fallen weg, sobald
/// die Assets aus dem Art-Direction-Thread da sind (docs/art/asset-vertrag.md).
@MainActor
enum BattleStyle {
    static let background = SKColor(red: 0.20, green: 0.34, blue: 0.22, alpha: 1)
    static let path = SKColor(red: 0.62, green: 0.50, blue: 0.33, alpha: 1)
    static let pathWidth: CGFloat = 0.8
    static let buildZone = SKColor(white: 1, alpha: 0.07)
    static let buildZoneInset: CGFloat = 0.06

    static func towerColor(_ kind: TowerKind) -> SKColor {
        switch kind {
        case .watch: SKColor(red: 0.85, green: 0.78, blue: 0.62, alpha: 1)
        case .lightning: SKColor(red: 0.45, green: 0.65, blue: 1.00, alpha: 1)
        case .spore: SKColor(red: 0.62, green: 0.85, blue: 0.35, alpha: 1)
        }
    }

    static func enemyColor(_ kind: EnemyKind) -> SKColor {
        switch kind {
        case .raider: SKColor(red: 0.85, green: 0.30, blue: 0.25, alpha: 1)
        case .runner: SKColor(red: 0.95, green: 0.65, blue: 0.20, alpha: 1)
        case .brute: SKColor(red: 0.55, green: 0.25, blue: 0.55, alpha: 1)
        }
    }

    /// Größen in Feldern, wie im Asset-Vertrag.
    static let towerFootprint: CGFloat = 0.8
    static let towerHeight: CGFloat = 1.1
    /// Gemalte Bilder sind Quadrate mit dem Fuß auf Höhe des Ankers
    /// (art/asset-vertrag.json; die CI prüft die Bilder dagegen).
    static let towerSpriteSide: CGFloat = 1.9
    static let fortressSpriteSide: CGFloat = 2.4
    static let fortressAnchorY: CGFloat = 0.15
    static func enemyHeight(_ kind: EnemyKind) -> CGFloat { kind == .brute ? 1.2 : 0.9 }
    static let shadow = SKColor(white: 0, alpha: 0.3)

    static let healthBack = SKColor(white: 0, alpha: 0.6)
    static let healthFill = SKColor(red: 0.35, green: 0.90, blue: 0.40, alpha: 1)
    static let healthWidth: CGFloat = 0.7
    static let healthHeight: CGFloat = 0.08
    static let slowTint = SKColor(red: 0.62, green: 0.85, blue: 0.35, alpha: 1)

    static let bolt = SKColor(red: 0.80, green: 0.88, blue: 1.00, alpha: 1)
    static let arrow = SKColor(red: 1.00, green: 0.95, blue: 0.80, alpha: 1)
    static let sporeCloud = SKColor(red: 0.62, green: 0.85, blue: 0.35, alpha: 0.35)
    static let gold = SKColor(red: 1.00, green: 0.84, blue: 0.25, alpha: 1)
    static let leak = SKColor(red: 1.00, green: 0.25, blue: 0.20, alpha: 1)
    static let fortress = SKColor(red: 0.55, green: 0.55, blue: 0.62, alpha: 1)

    static let shotLife: TimeInterval = 0.10
    static let boltLife: TimeInterval = 0.18
    static let pulseLife: TimeInterval = 0.35
    static let hitFlash: TimeInterval = 0.06
    static let deathLife: TimeInterval = 0.30
    static let floatLife: TimeInterval = 0.70
    static let bannerLife: TimeInterval = 1.6
    static let font = "AvenirNext-Heavy"
    static let fastSpeed = 2

    static let selection = SKColor(red: 1.00, green: 0.95, blue: 0.70, alpha: 1)
    static let rangeFill = SKColor(red: 1.00, green: 0.95, blue: 0.70, alpha: 0.10)

    /// Bedienung: Apples Mindestgröße für Tippziele ist 44 pt.
    static let tapTarget: CGFloat = 48
    static let menuSpacing: CGFloat = 6
    static let menuPadding: CGFloat = 6
    static let screenMargin: CGFloat = 8
    /// Knapp unter der Tippgröße: Im Querformat zählt jeder Punkt Höhe für die Karte.
    static let hudHeight: CGFloat = 40
    static let hudMargin: CGFloat = 6
    /// Kreismenü (07-ui-ux.md, Grundsatz 5): runde Knöpfe deutlich über 44 pt.
    static let ringButton: CGFloat = 54
    static let ringGap: CGFloat = 6
    static let infoPanel = CGSize(width: 214, height: 96)
    static var hudMetrics: HudLayout.Metrics {
        HudLayout.Metrics(button: ringButton, gap: ringGap, margin: screenMargin, panel: infoPanel)
    }

    /// Längste Bildzeit, die nachgeholt wird.
    static let maxCatchUp: TimeInterval = 0.25
}
