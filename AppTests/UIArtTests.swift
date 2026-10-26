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
        for name in ["ui_icon_heart", "ui_icon_gold"] {
            XCTAssertNotNil(UITheme.image(name), name)
        }
    }
}
