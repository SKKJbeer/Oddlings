import OddlingsCore
import XCTest

/// Zwergenbank und frühes Rufen in Mission 2, mit echtem Tippen (P2-5).
/// Preise, Bonus und Höchstzahl kommen aus `mission-02.json`.
final class BankE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    private func launch() throws -> E2EApp {
        // Welle zurückgehalten: Bis zur ersten Auszahlung vergeht mehr Zeit als
        // bis zum Ablesen, also stimmt der Goldvergleich genau.
        let e2e = try E2EApp(["--play", "--e2e-knoten", "m2", "--e2e-erste-welle", E2EApp.wavesOnHold],
                             mission: "mission-02")
        e2e.waitForBoard()
        return e2e
    }

    @MainActor
    func testBankIsOfferedAndCostsItsPrice() throws {
        let e2e = try launch()
        let bank = try XCTUnwrap(e2e.config.bank, "Mission 2 hat eine Bank")
        let start = e2e.config.mission.startGold
        let cell = try XCTUnwrap(e2e.map.buildableCells.first)
        e2e.tap(cell)
        let button = e2e.build(.bank)
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Kreismenü bietet die Bank an")
        XCTAssertTrue(button.label.contains("Zwergenbank"), button.label)
        button.tap()
        XCTAssertTrue(e2e.app.staticTexts["Die \(bank.cost) Gold fehlen dir in den nächsten Wellen."]
            .waitForExistence(timeout: 5), "Vorschau nennt den Preis des Wartens")
        button.tap()
        e2e.waitFor(e2e.gold, toBe: start - bank.cost, "Bauen zieht den Bankpreis ab")
        e2e.screenshot("p2-5-bank-gebaut", in: self)
    }

    @MainActor
    func testEarlyCallPaysAndSecondBankHitsLimit() throws {
        let e2e = try launch()
        let bank = try XCTUnwrap(e2e.config.bank)
        XCTAssertTrue(e2e.nextWave.waitForExistence(timeout: 5))
        XCTAssertTrue(e2e.nextWave.label.contains("Gold"), "Knopf nennt den Bonus: \(e2e.nextWave.label)")

        var cells = e2e.map.buildableCells.makeIterator()
        e2e.build(.bank, at: try XCTUnwrap(cells.next()))
        let before = e2e.gold
        e2e.nextWave.tap()
        // Die Welle wartete 600 s; der Bonus dafür reicht für jede weitere Bank.
        let end = Date().addingTimeInterval(5)
        while e2e.gold < before + bank.cost && Date() < end { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
        XCTAssertGreaterThanOrEqual(e2e.gold, before + bank.cost, "frühes Rufen schreibt Gold gut")

        for _ in 1..<bank.limit { e2e.build(.bank, at: try XCTUnwrap(cells.next())) }
        e2e.tap(try XCTUnwrap(cells.next()))
        let button = e2e.build(.bank)
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        XCTAssertTrue(button.label.contains("Höchstens \(bank.limit) Banken"), button.label)
        let gold = e2e.gold
        button.tap()
        button.tap()
        XCTAssertTrue(button.exists, "an der Höchstzahl baut nichts, das Menü bleibt offen")
        XCTAssertGreaterThanOrEqual(e2e.gold, gold, "kein Gold abgezogen")
    }
}
