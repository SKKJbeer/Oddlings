import OddlingsCore
import XCTest
@testable import Oddlings

/// Gemalte Oberflächenbilder (Grafik 03). Die Ansichten fallen still auf
/// SF Symbols oder gezeichnete Formen zurück, wenn ein Name nicht stimmt; das
/// soll hier rot werden, nicht erst beim Spieltest.
final class UIArtTests: XCTestCase {
    func testRingMenuFindsAPaintedIconForEveryTower() throws {
        for kind in TowerKind.allCases {
            let picture = try XCTUnwrap(UITheme.image("ui_tower_\(kind.rawValue)"), "\(kind)")
            // Quadrat, weil der Ringknopf es zentriert und nicht beschneidet.
            XCTAssertEqual(picture.size.width, picture.size.height, "\(kind)")
        }
    }

    func testHudIconsAreInTheCatalog() {
        for name in ["ui_icon_heart", "ui_icon_gold", "ui_icon_wave", "ui_icon_sell", "ui_icon_pause", "ui_icon_next_wave"] {
            XCTAssertNotNil(UITheme.image(name), name)
        }
    }

    func testMenuKeyArtIsPaintedLandscape() throws {
        let picture = try XCTUnwrap(UITheme.image("ui_keyart_menu"))
        // Querformat wie das breiteste iPhone, damit scaledToFill nur oben und unten wenig abschneidet.
        XCTAssertEqual(picture.size.width / picture.size.height, 2796.0 / 1290.0, accuracy: 0.01)
    }

    func testCampaignMapIsPaintedInTheMapAspect() throws {
        // Ohne Bild zeichnet die Karte still den Ersatzwald; mit falschem Seitenverhältnis
        // lägen die Knoten neben ihren Lichtungen.
        let picture = try XCTUnwrap(UITheme.image(CampaignStyle.mapImage))
        XCTAssertEqual(picture.size.width / picture.size.height, CampaignStyle.mapAspect, accuracy: 0.01)
    }
}
