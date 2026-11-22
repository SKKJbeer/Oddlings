import OddlingsCore
import UIKit
import XCTest
@testable import Oddlings

/// Jede Zeile der Tafeln passt in voller Größe (A-2, P5): gemessen mit der
/// echten Schrift und den längsten Zahlen aller Missionen. `minimumScaleFactor`
/// bleibt im Code als Netz, nötig sein darf er nicht. Was hier rot wird, wird
/// umformuliert, nicht kleiner gesetzt.
@MainActor
final class TextFitTests: XCTestCase {
    private enum Face { case display, body, heavy }

    private var missions: [BalanceConfig] {
        get throws {
            let names = ["mission-02", "mission-03", "mission-04", "mission-05a", "mission-05b",
                         "mission-06a", "mission-06b", "mission-07"]
            return [try BalanceConfig.missionOne()] + (try names.map { try BalanceConfig.bundledMission(named: $0) })
        }
    }

    override func setUp() {
        super.setUp()
        AppFonts.register()
    }

    private func width(_ text: String, _ face: Face, _ size: CGFloat) throws -> CGFloat {
        let name = switch face {
        case .display: AppFonts.display
        case .body: AppFonts.body
        case .heavy: AppFonts.bodyHeavy
        }
        let font = try XCTUnwrap(UIFont(name: name, size: size), "\(name) fehlt")
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    private func assertFits(_ texts: [String], _ face: Face, _ size: CGFloat, in room: CGFloat, _ slot: String,
                            file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertFalse(texts.isEmpty, slot, file: file, line: line)
        for text in texts {
            let need = try width(text, face, size)
            XCTAssertLessThanOrEqual(need, room, "\(slot): „\(text)“ braucht \(need) von \(room) pt", file: file, line: line)
        }
    }

    /// Höchste Preise und Erträge über alle Missionen, damit die längsten Zahlen geprüft werden.
    private struct Prices { var build = 0, upgrade = 0, special = 0, bankCap = 0, bankPayout = 0, bankDelay = 0.0, bankInterval = 0.0 }

    private func prices() throws -> Prices {
        var p = Prices()
        for config in try missions {
            for kind in TowerKind.allCases {
                p.build = max(p.build, config.towers[kind]?.cost ?? 0)
                p.upgrade = max(p.upgrade, config.upgrades?[kind]?.cost ?? 0)
            }
            for specialization in Specialization.allCases {
                p.special = max(p.special, config.specializations?[specialization]?.cost ?? 0)
            }
            if let bank = config.bank {
                p.build = max(p.build, bank.cost)
                p.bankCap = max(p.bankCap, bank.cap)
                p.bankPayout = max(p.bankPayout, bank.payout)
                p.bankDelay = max(p.bankDelay, bank.delay)
                p.bankInterval = max(p.bankInterval, bank.interval)
            }
        }
        XCTAssertGreaterThan(p.special, 0, "Spezialisierungen in den Missionen")
        return p
    }

    private var bankForMeasure: BankConfig {
        get throws {
            let p = try prices()
            var bank = try XCTUnwrap(try missions.compactMap(\.bank).first)
            bank.cost = p.build
            bank.cap = p.bankCap
            bank.payout = p.bankPayout
            bank.delay = p.bankDelay
            bank.interval = p.bankInterval
            return bank
        }
    }

    /// Hohe Tafel mit Turmwerten: Titel, eine Zeile, was das nächste Tippen tut.
    func testStatPanelLinesFit() throws {
        let p = try prices()
        let room = BattleStyle.statPanel.width - 2 * BattleStyle.statPanelPadding
        let titles = TowerKind.combat.flatMap { kind in
            [BattleTexts.name(kind, level: 2), "\(BattleTexts.name(kind)) → \(BattleTexts.levelTag(2))"]
                + Specialization.allCases.filter { $0.tower == kind }
                    .map { "\(BattleTexts.name(kind, level: 2)) → \(BattleTexts.name($0))" }
        }
        try assertFits(titles, .display, 18, in: room, "Titel")

        var tower = Tower(id: 1, kind: .watch, cell: Cell(x: 0, y: 0), cooldownTicks: 0, spent: 0)
        tower.damageDealt = 99_999
        tower.kills = 999
        var spore = tower
        spore.kind = .spore
        spore.slowHits = 9_999
        let longest = 59 * 60 + 59
        try assertFits([TowerStatTexts.newTargetMode, BattleTexts.upgradeUnlocksNothing, BattleTexts.chooseSpecialization,
                        TowerStatTexts.tally(tower, seconds: longest), TowerStatTexts.tally(spore, seconds: longest)],
                       .body, 12, in: room, "Zeile")
        try assertFits(Specialization.allCases.map(BattleTexts.specializeDrops) + [BattleTexts.specializeFinal],
                       .heavy, 12, in: room, "Warnung")
        try assertFits([BattleTexts.confirmUpgrade(p.upgrade), BattleTexts.upgradeLine(p.upgrade),
                        BattleTexts.confirmSell(refund: p.special), BattleTexts.refundLine(p.special),
                        BattleTexts.chooseOneStar, BattleTexts.tapAgainToBuild]
                       + Specialization.allCases.flatMap {
                           [BattleTexts.confirmSpecialize($0, cost: p.special), BattleTexts.specializeLine($0, cost: p.special)]
                       },
                       .heavy, 13, in: room, "Nächstes Tippen")
    }

    /// Kleine Tafel: die Bank, und was ohne Turmwerte dasteht.
    func testInfoPanelLinesFit() throws {
        let p = try prices()
        let bank = try bankForMeasure
        let room = BattleStyle.infoPanel.width - 2 * BattleStyle.infoPanelPadding
        try assertFits(TowerKind.allCases.map(BattleTexts.name), .display, 19, in: room, "Titel")
        try assertFits(TowerKind.allCases.flatMap { [BattleTexts.role($0), BattleTexts.combo($0)] }
                       + [BattleTexts.bankIncome(bank), BattleTexts.bankPaid(bank.cap, of: bank.cap), BattleTexts.bankEmpty,
                          BattleTexts.upgradeUnlocks, BattleTexts.upgradeUnlocksNothing]
                       + Specialization.allCases.map(BattleTexts.effect),
                       .body, 13, in: room, "Zeile")
        try assertFits([BattleTexts.bankWarning(cost: bank.cost)] + Specialization.allCases.map(BattleTexts.specializeDrops),
                       .heavy, 13, in: room, "Warnung")
        try assertFits([BattleTexts.tapAgainToBuild, BattleTexts.confirmSell(refund: p.build), BattleTexts.refundLine(p.build)],
                       .heavy, 13, in: room, "Nächstes Tippen")
    }

    /// Der Zettel unter dem Wellenknopf: Zahl neben dem Bild, drei Arten.
    func testForecastCountsFit() throws {
        var most = 0
        for config in try missions {
            for index in config.waves.indices {
                for entry in WaveForecast(waves: config.waves, index: index)?.entries ?? [] { most = max(most, entry.count) }
            }
        }
        let room = BattleStyle.forecastEntry - BattleStyle.forecastIcon - 2  // Abstand im HStack des Zettels
        try assertFits(["\(most)"], .display, 15, in: room, "Anzahl auf dem Zettel")
    }
}
