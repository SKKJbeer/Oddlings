import OddlingsCore
import XCTest

/// Avatar-Aufbau (R-5, r-5-avatar.md): beim ersten „Spielen“ Volk, Porträt und
/// Name wählen, danach ist das Volk gesetzt, prägt jede Mission und übersteht
/// den Neustart der App.
final class AvatarE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    private func tapPlay(_ e2e: E2EApp) {
        let play = e2e.app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        play.tap()
    }

    @MainActor
    func testAvatarIsBuiltOnceAndSurvivesRelaunch() throws {
        let e2e = try E2EApp(["--e2e-erste-welle", E2EApp.wavesOnHold], storage: "avatar")
        XCTAssertFalse(e2e.app.otherElements["menu.avatar"].exists, "vor dem Aufbau kein Avatarschild")
        tapPlay(e2e)
        XCTAssertTrue(e2e.setup.waitForExistence(timeout: 5), "ohne Avatar erst der Aufbau")
        XCTAssertFalse(e2e.mapStart.exists)
        XCTAssertFalse(e2e.setupConfirm.isEnabled, "erst ein Volk wählen")

        e2e.setupRace(.elves).tap()
        XCTAssertTrue(e2e.setupRace(.elves).isSelected)
        XCTAssertFalse(e2e.setupRace(.dwarves).isSelected)
        let suggested = e2e.setupName.value as? String ?? ""
        XCTAssertNotNil(Avatar.validName(suggested), "ein Name steht schon im Feld: \(suggested)")
        XCTAssertTrue(e2e.setupPortrait("elf-1").isSelected, "das erste Porträt des Volks ist vorgewählt")
        XCTAssertFalse(e2e.setupPortrait("dwarf-1").exists, "nur Porträts des gewählten Volks")
        XCTAssertTrue(e2e.setupConfirm.isEnabled)
        e2e.setupPortrait("elf-2").tap()
        XCTAssertTrue(e2e.setupPortrait("elf-2").isSelected)
        XCTAssertFalse(e2e.setupPortrait("elf-1").isSelected)

        // Eigenen Namen tippen: Cursor ans Ende, Vorschlag löschen.
        e2e.setupName.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: suggested.count + 2)
        e2e.setupName.typeText(delete)
        XCTAssertFalse(e2e.setupConfirm.isEnabled, "ohne Namen kein Avatar")
        e2e.setupName.typeText("Lyra\n")
        XCTAssertEqual(e2e.setupName.value as? String, "Lyra")
        e2e.screenshot("6-avatar", in: self)
        e2e.setupConfirm.tap()

        XCTAssertTrue(e2e.mapStart.waitForExistence(timeout: 5), "nach dem Aufbau die Karte")
        XCTAssertEqual(e2e.mapAvatar.label, "Lyra, Elfen")
        XCTAssertTrue(e2e.raceDetail.contains("Mondmal"), e2e.raceDetail)
        XCTAssertFalse(e2e.app.buttons["map.race.dwarves"].exists, "auf der Tafel gibt es keine Volkswahl mehr")
        e2e.mapStart.tap()
        e2e.waitForBoard()
        XCTAssertTrue(e2e.ability.waitForExistence(timeout: 5))
        XCTAssertEqual(e2e.ability.label, "Mondmal")

        e2e.app.terminate()
        let again = try E2EApp(storage: "avatar", fresh: false)
        let badge = again.app.otherElements["menu.avatar"]
        XCTAssertTrue(badge.waitForExistence(timeout: 15), "Avatarschild im Hauptmenü")
        XCTAssertEqual(badge.label, "Lyra, Elfen")
        tapPlay(again)
        XCTAssertTrue(again.mapStart.waitForExistence(timeout: 5), "kein zweiter Aufbau")
        XCTAssertFalse(again.setup.exists)
        XCTAssertEqual(again.mapAvatar.label, "Lyra, Elfen", "Name und Volk stehen im Spielstand")
    }

    /// D-062: Ein Zwerg zahlt für den Wachturm weniger, sichtbar im Ring und
    /// an der Kasse, und wirkt das Bollwerk.
    @MainActor
    func testDwarfAvatarGetsItsPriceAndAbility() throws {
        let e2e = try E2EApp(["--play", "--e2e-erste-welle", E2EApp.wavesOnHold, "--e2e-abklingzeit", E2EApp.abilityOnHold],
                             avatar: .dwarves)
        e2e.waitForBoard()
        let dwarves = e2e.config.applying(try XCTUnwrap(try RaceTable.bundled()[.dwarves]))
        let price = try XCTUnwrap(dwarves.towers[.watch]?.cost)
        XCTAssertLessThan(price, e2e.cost(.watch))
        let cell = try XCTUnwrap(e2e.map.buildableCells.first)
        let gold = e2e.gold
        e2e.tap(cell)
        XCTAssertTrue(e2e.build(.watch).waitForExistence(timeout: 5))
        XCTAssertTrue(e2e.build(.watch).label.contains("\(price)"), e2e.build(.watch).label)
        e2e.build(.watch).tap()
        e2e.build(.watch).tap()
        e2e.waitFor(e2e.gold, toBe: gold - price, "der Zwergenpreis wird abgebucht")
        XCTAssertTrue(e2e.ability.waitForExistence(timeout: 5))
        XCTAssertEqual(e2e.ability.label, "Bollwerk")
        XCTAssertEqual(e2e.abilityState, "bereit")
        e2e.ability.tap()
        e2e.tap(e2e.map.path.position(at: e2e.map.path.length / 3))
        let charging = NSPredicate(format: "value BEGINSWITH %@", "lädt")
        expectation(for: charging, evaluatedWith: e2e.ability)
        waitForExpectations(timeout: 5)
    }

    /// Im Querformat ist wenig Platz: Im Aufbau und auf der Tafel mit Avatar darf
    /// nichts übereinander liegen oder aus dem Bild ragen.
    @MainActor
    func testSetupAndPanelFitTheScreen() throws {
        let e2e = try E2EApp(storage: "passt")
        tapPlay(e2e)
        XCTAssertTrue(e2e.setup.waitForExistence(timeout: 5))
        e2e.setupRace(.dwarves).tap()
        assertFits([e2e.setupRace(.dwarves), e2e.setupRace(.elves), e2e.setupPortrait("dwarf-1"),
                    e2e.setupPortrait("dwarf-2"), e2e.setupPortrait("dwarf-3"), e2e.setupName,
                    e2e.app.buttons["setup.name.suggest"], e2e.setupConfirm], in: e2e)
        e2e.setupConfirm.tap()
        XCTAssertTrue(e2e.mapStart.waitForExistence(timeout: 5))
        assertFits([e2e.app.staticTexts["map.panel.title"], e2e.mapAvatar, e2e.app.staticTexts["map.race.detail"],
                    e2e.app.staticTexts["map.panel.status"], e2e.mapStart], in: e2e)
    }

    @MainActor
    private func assertFits(_ parts: [XCUIElement], in e2e: E2EApp, file: StaticString = #filePath, line: UInt = #line) {
        let window = e2e.app.windows.firstMatch.frame
        for part in parts {
            XCTAssertTrue(part.waitForExistence(timeout: 5), part.identifier, file: file, line: line)
            XCTAssertTrue(window.contains(part.frame), "\(part.identifier) liegt im Bild: \(part.frame)", file: file, line: line)
            XCTAssertTrue(part.isHittable, part.identifier, file: file, line: line)
        }
        for (index, part) in parts.enumerated() {
            for other in parts[(index + 1)...] {
                XCTAssertFalse(part.frame.intersects(other.frame), "\(part.identifier) und \(other.identifier) überlappen",
                               file: file, line: line)
            }
        }
    }
}
