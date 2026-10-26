import OddlingsCore
import XCTest

/// Die App aus Sicht eines Spielers: starten, tippen, ablesen. Alle
/// End-zu-End-Tests gehen über diesen Typ, damit Kennungen und die
/// Lagerechnung der Karte nur an einer Stelle stehen.
///
/// Zahlen (Preise, Startgold, Erstattung) kommen aus der Missionsdatei über
/// OddlingsCore, nie aus dem Test: Eine Balanceänderung bricht keinen
/// Oberflächentest.
@MainActor
struct E2EApp {
    let app = XCUIApplication()
    let config: BalanceConfig
    let sim: Simulation
    var map: MissionMap { sim.map }

    /// Zeitraffer für ganze Missionen. Gleiche feste Schritte, nur mehr je Bild.
    static let fastForward = "40"
    /// Langsamerer Zeitraffer, wenn der Test nach einem Neustart noch ablesen
    /// muss: Bei 40× ist die erste Welle schon da, bevor die Abfrage antwortet,
    /// und die Leben fallen wieder (im ersten Lauf so gesehen).
    static let readableFastForward = "10"

    /// Jeder Test spielt mit eigenem Spielstand im temporären Ordner, damit ein
    /// Sieg aus einem Test den nächsten nicht verändert. `fresh: false` startet
    /// auf dem Stand, den ein früherer Start mit derselben `storage` schrieb.
    init(_ arguments: [String] = [], storage: String = "standard", fresh: Bool = true) throws {
        config = try BalanceConfig.missionOne()
        sim = Simulation(config: config)
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launchArguments = arguments + ["--e2e-speicher", storage] + (fresh ? ["--e2e-frisch"] : [])
        app.launch()
    }

    // MARK: Elemente

    var board: XCUIElement { app.otherElements["battle.board"] }
    var gold: Int { number(in: app.staticTexts["hud.gold"]) }
    var lives: Int { number(in: app.staticTexts["hud.lives"]) }
    var waveLabel: String { app.staticTexts["hud.wave"].label }
    var nextWave: XCUIElement { app.buttons["hud.nextWave"] }
    var pause: XCUIElement { app.buttons["hud.pause"] }
    var speed: XCUIElement { app.buttons["hud.speed"] }
    var result: XCUIElement { app.staticTexts["result.title"] }
    var pausedHint: XCUIElement { app.staticTexts["hud.paused"] }
    func build(_ kind: TowerKind) -> XCUIElement { app.buttons["build.\(kind.rawValue)"] }
    var sell: XCUIElement { app.buttons["sell"] }
    var sellConfirm: XCUIElement { app.staticTexts["sell.confirm"] }
    var pauseCard: XCUIElement { app.otherElements["pause.card"] }
    var resume: XCUIElement { app.buttons["pause.resume"] }
    var restart: XCUIElement { app.buttons["pause.restart"] }
    var giveUp: XCUIElement { app.buttons["pause.quit"] }
    var mapView: XCUIElement { app.otherElements["map"] }
    var mapStart: XCUIElement { app.buttons["map.start"] }
    var mapBack: XCUIElement { app.buttons["map.back"] }
    func node(_ id: String) -> XCUIElement { app.buttons["map.node.\(id)"] }
    /// Was ein Knoten zeigt, in Worten (CampaignTexts.accessibilityValue).
    func nodeState(_ id: String) -> String { node(id).value as? String ?? "" }
    /// Wert einer Kachel der Ergebnistafel, z. B. `result.lives`. Vorgelesen
    /// wird immer der echte Wert, auch während die Anzeige noch hochzählt.
    func resultValue(_ id: String) -> String { app.staticTexts[id].label }

    func cost(_ kind: TowerKind) -> Int { config.towers[kind]?.cost ?? 0 }

    // MARK: Handlungen

    func waitForBoard(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(board.waitForExistence(timeout: 15), "Karte erscheint", file: file, line: line)
    }

    /// Tippt die Mitte einer Zelle, mit derselben Rechnung wie BoardLayout:
    /// Seitenverhältnis einpassen, mittig.
    func tap(_ cell: Cell) {
        let size = board.frame.size
        let field = min(size.width / CGFloat(map.width), size.height / CGFloat(map.height))
        let x = (size.width - field * CGFloat(map.width)) / 2 + (CGFloat(cell.x) + 0.5) * field
        let y = (size.height - field * CGFloat(map.height)) / 2 + (CGFloat(cell.y) + 0.5) * field
        board.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
    }

    /// Bauen wie ein Spieler: Zelle, Turm (Vorschau), Turm (bauen).
    func build(_ kind: TowerKind, at cell: Cell, file: StaticString = #filePath, line: UInt = #line) {
        tap(cell)
        let button = build(kind)
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Baumenü öffnet", file: file, line: line)
        button.tap()
        button.tap()
        XCTAssertTrue(button.waitForNonExistence(timeout: 5), "Menü schließt nach dem Bau", file: file, line: line)
    }

    /// Wartet, bis eine Zahl im HUD den erwarteten Wert hat. Momentaufnahmen
    /// wären unzuverlässig: Die Oberfläche folgt dem Zustand ein Bild später.
    func waitFor(_ value: @autoclosure () -> Int, toBe expected: Int, timeout: TimeInterval = 5,
                 _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        let end = Date().addingTimeInterval(timeout)
        var last = value()
        while last != expected && Date() < end {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            last = value()
        }
        XCTAssertEqual(last, expected, message, file: file, line: line)
    }

    /// Wartet, bis ein Element genau diese Beschriftung trägt.
    func waitFor(_ element: XCUIElement, label expected: String, timeout: TimeInterval = 5,
                 file: StaticString = #filePath, line: UInt = #line) {
        let end = Date().addingTimeInterval(timeout)
        while element.label != expected && Date() < end {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertEqual(element.label, expected, file: file, line: line)
    }

    /// Bildschirmfoto als Anhang und, wenn die CI einen Ordner nennt
    /// (`ODDLINGS_BILDER`), als Datei zum Vergleich mit dem Entwurf.
    func screenshot(_ name: String, in test: XCTestCase) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)
        if let folder = ProcessInfo.processInfo.environment["ODDLINGS_BILDER"], !folder.isEmpty {
            let url = URL(fileURLWithPath: folder).appendingPathComponent("\(name).png")
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? shot.pngRepresentation.write(to: url)
        }
    }

    private func number(in element: XCUIElement) -> Int {
        Int(element.label.split(separator: " ").first ?? "") ?? -1
    }
}
