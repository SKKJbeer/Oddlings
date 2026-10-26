import OddlingsCore
import SwiftUI

/// Farben und Schriften kommen aus `UITheme`; hier steht nur, was die Karte
/// allein braucht. Aussehen der gezeichneten Karte, bis `map_region01` aus dem Grafik-Thread da
/// ist; dann bleiben nur Knoten, Tafel und Seitenverhältnis.
enum CampaignStyle {
    /// Seitenverhältnis des Kartenbilds (16:10). Die Knotenlagen in
    /// region-01.json beziehen sich darauf; die Karte wird eingepasst, nie
    /// beschnitten, damit auf keinem Gerät ein Knoten fehlt.
    static let mapAspect: CGFloat = 1.6
    static let mapImage = "map_region01"
    static let panelWidth: CGFloat = 280
    static let margin: CGFloat = 12

    static let forestDeep = Color(red: 0.07, green: 0.14, blue: 0.10)
    static let forest = Color(red: 0.16, green: 0.30, blue: 0.19)
    static let forestLight = Color(red: 0.30, green: 0.47, blue: 0.27)
    static let swamp = Color(red: 0.24, green: 0.33, blue: 0.27)
    static let ruins = Color(red: 0.42, green: 0.40, blue: 0.34)
    static let trail = Color(red: 0.86, green: 0.76, blue: 0.56)
    static let gold = UITheme.coin
    static let goldDark = UITheme.goldShade
    static let wood = UITheme.woodFace
    static let woodDark = UITheme.wood
    static let parchment = UITheme.parchment
    static let locked = Color(white: 0.42)
    static let ink = UITheme.outline

    static let mainNode: CGFloat = 52
    static let bossNode: CGFloat = 66
    static let sideNode: CGFloat = 44
    static let starSize: CGFloat = 13
    static let trailWidth: CGFloat = 5
    static let ring: CGFloat = 4
    static let pulse: Double = 1.4
    /// Apples Mindestgröße für Tippziele, nicht mehr: Im Querformat zählt jeder
    /// Punkt Höhe auf der Tafel.
    static let raceButtonHeight: CGFloat = 44

    static func raceSymbol(_ race: Race) -> String {
        switch race {
        case .dwarves: "hammer.fill"
        case .elves: "leaf.fill"
        }
    }
}
