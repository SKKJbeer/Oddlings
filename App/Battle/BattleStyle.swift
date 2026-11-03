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
    /// So viele Zellen reicht der gemalte Boden links und rechts (`width`) und
    /// oben und unten (`height`) über das Feld hinaus. Unter der Kopfleiste ist
    /// die Karte auf dem iPhone bis zu 22,7 Zellen breit, auf dem iPad bis zu
    /// 11,3 hoch. Steht auch im Asset-Vertrag (`rand`).
    static let groundMargin = CGSize(width: 4, height: 2)

    static func towerColor(_ kind: TowerKind) -> SKColor {
        switch kind {
        case .watch: SKColor(red: 0.85, green: 0.78, blue: 0.62, alpha: 1)
        case .lightning: SKColor(red: 0.45, green: 0.65, blue: 1.00, alpha: 1)
        case .spore: SKColor(red: 0.62, green: 0.85, blue: 0.35, alpha: 1)
        case .bank: SKColor(red: 0.95, green: 0.78, blue: 0.30, alpha: 1)
        }
    }

    /// Zwergenbank (P2-5): Balken unter dem Turm, in Feldern unter dem Fuß.
    static let bankBarDrop: CGFloat = 0.32
    static let bankFill = SKColor(red: 1.00, green: 0.84, blue: 0.25, alpha: 1)
    static let bankSpent = SKColor(white: 0.55, alpha: 1)
    /// Schild „II“ oben rechts an einem aufgewerteten Turm (P2-6): Gold auf Dunkel wie die Preisschilder.
    static let levelBadgeFill = SKColor(red: 1.00, green: 0.84, blue: 0.25, alpha: 1)
    /// Schild gepanzerter Gegner (P2-10): kühles Eisen, dunkler Rand, Höhe in Feldern.
    static let armorBadgeFill = SKColor(red: 0.72, green: 0.76, blue: 0.82, alpha: 1)
    static let armorBadgeStroke = SKColor(red: 0.20, green: 0.22, blue: 0.27, alpha: 1)
    static let armorBadgeSize: CGFloat = 0.26
    static let levelBadgeStroke = SKColor(red: 0x22 / 255, green: 0x16 / 255, blue: 0x0F / 255, alpha: 1)
    static let bankEmptyAlpha: CGFloat = 0.6

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
    /// Die Festung steht im Rand hinter dem Wegende, nicht im Feld: Dort ist jede
    /// Zelle neben dem Weg bebaubar. Zellen nach rechts und unten vom Wegende.
    static let fortressOffset = CGPoint(x: 0.85, y: 0.9)
    /// Reihenfolge innerhalb der Bodenebene. `ignoresSiblingOrder` zeichnet
    /// Geschwister mit gleicher zPosition beliebig; bis 0.10.3 lag so die
    /// Festung unter dem Boden.
    static let groundZ: CGFloat = -1
    static let fortressZ: CGFloat = 1
    static func enemyHeight(_ kind: EnemyKind) -> CGFloat { kind == .brute ? 1.2 : 0.9 }

    static let healthBack = SKColor(white: 0, alpha: 0.6)
    static let healthFill = SKColor(red: 0.35, green: 0.90, blue: 0.40, alpha: 1)
    static let healthWidth: CGFloat = 0.7
    static let healthHeight: CGFloat = 0.08

    static let leak = SKColor(red: 1.00, green: 0.25, blue: 0.20, alpha: 1)
    static let fortress = SKColor(red: 0.55, green: 0.55, blue: 0.62, alpha: 1)

    /// Mondmal am Gegner (R-4); die Effekte der Fähigkeiten stehen in `FxStyle`.
    static let markTint = SKColor(red: 0.70, green: 0.75, blue: 1.00, alpha: 1)
    /// Mauer in Feldern: quer zum Weg so breit wie der Weg, dazu die Dicke.
    static let wallLength: CGFloat = 1.1
    static let wallThickness: CGFloat = 0.28
    /// So weit vor und hinter der Mauer wird die Wegrichtung abgelesen.
    static let wallProbe: Double = 0.05
    static func abilitySymbol(_ kind: AbilityKind) -> String {
        switch kind {
        case .stoneRain: "circle.hexagongrid.circle.fill"
        case .bulwark: "shield.lefthalf.filled"
        case .moonMark: "moon.stars.fill"
        }
    }
    /// Lilita One (D-032), angemeldet in `AppFonts`.
    static let font = AppFonts.display
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

    /// Einstieg (P2-8): so lange zögert der Spieler, bevor die Hand bzw. der
    /// Pfeil kommt. Schätzung bis zum Spieltest (S3), Bedienung, kein Spielwert.
    static let guideBuildDelay: Double = 6
    static let guideWaveDelay: Double = 5

    /// Längste Bildzeit, die nachgeholt wird.
    static let maxCatchUp: TimeInterval = 0.25
}
