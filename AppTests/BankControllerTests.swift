import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Zwergenbank und frühes Rufen in der Bedienung (P2-5). Werte aus
/// `mission-02.json`, damit eine Balanceänderung keinen Test bricht.
@MainActor
final class BankControllerTests: XCTestCase {
    private lazy var config: BalanceConfig = try! BalanceConfig.bundledMission(named: "mission-02")
    /// Testkonfiguration: Gold für eine Bank über der Höchstzahl und eine
    /// Welle, die nicht kommt, damit eine Bank in Ruhe leer läuft.
    private lazy var rich: BalanceConfig = {
        var copy = config
        copy.mission.startGold = bank.cost * (bank.limit + 1)
        copy.mission.firstWaveDelay = bank.delay + bank.interval * Double(bank.cap / bank.payout + 10)
        return copy
    }()
    private lazy var model = BattleModel(config: config, seed: 1, autoplay: false)
    private lazy var controller = BattleController(model: model, interactive: true)
    private lazy var bank: BankConfig = config.bank!
    private var felt: [Haptic] = []

    private func stepAndRefresh() { controller.afterFrame(events: model.step()) }

    private func build(_ kind: TowerKind, at cell: Cell) {
        controller.tap(cell)
        controller.choose(kind)
        controller.choose(kind)
        stepAndRefresh()
    }

    func testMissionTwoOffersTheBankMissionOneDoesNot() throws {
        XCTAssertEqual(controller.buildable, TowerKind.combat + [.bank])
        XCTAssertEqual(controller.cost(of: .bank), bank.cost)
        let first = BattleController(model: BattleModel(config: try BalanceConfig.missionOne(), seed: 1, autoplay: false),
                                     interactive: true)
        XCTAssertEqual(first.buildable, TowerKind.combat, "Mission 1 bleibt, wie sie im Spieltest ist")
        XCTAssertNil(first.bank)
        XCTAssertEqual(first.callBonus, 0, "Mission 1 hat keinen Bonus fürs frühe Rufen")
    }

    func testBankLimitDimsAndSendsNothing() throws {
        model = BattleModel(config: rich, seed: 1, autoplay: false)
        controller = BattleController(model: model, interactive: true)
        controller.haptics = { [unowned self] in felt.append($0) }
        var cells = model.sim.map.buildableCells.makeIterator()
        for _ in 0..<bank.limit {
            let gold = model.state.gold
            build(.bank, at: try XCTUnwrap(cells.next()))
            XCTAssertEqual(model.state.gold, gold - bank.cost)
        }
        XCTAssertEqual(controller.banksStanding, bank.limit)
        XCTAssertTrue(controller.atLimit(.bank))
        XCTAssertFalse(controller.atLimit(.watch))
        XCTAssertEqual(controller.limitTag, "\(bank.limit)/\(bank.limit)")

        XCTAssertTrue(controller.canAfford(.bank), "nur die Höchstzahl hält auf, nicht das Gold")
        let cell = try XCTUnwrap(cells.next())
        controller.tap(cell)
        felt = []
        controller.choose(.bank)
        XCTAssertEqual(controller.selection, .cell(cell, choice: nil), "keine Vorschau an der Höchstzahl")
        XCTAssertEqual(controller.limitWarnings, 1)
        XCTAssertEqual(felt, [.warning])
        stepAndRefresh()
        XCTAssertEqual(controller.banksStanding, bank.limit, "kein Befehl ging hinaus")
    }

    func testCallBonusMatchesWhatTheSimulationPays() throws {
        stepAndRefresh()
        let shown = controller.callBonus
        XCTAssertGreaterThan(shown, 0, "vor der ersten Welle lohnt frühes Rufen")
        let gold = model.state.gold
        controller.callNextWave()
        stepAndRefresh()
        // Ein Takt liegt zwischen Anzeige und Gutschrift; mehr als ein Gold
        // darf das nicht ausmachen.
        XCTAssertLessThanOrEqual(abs(model.state.gold - gold - shown), 1)
        XCTAssertEqual(controller.bonusGains, 1)
        XCTAssertEqual(controller.lastBonus, model.state.gold - gold)
    }

    func testEmptyBankTurnsGreyAndBarFills() throws {
        let tower = Tower(id: 1, kind: .bank, cell: Cell(x: 0, y: 0), cooldownTicks: 0, spent: bank.cost)
        let node = TowerNode(tower: tower, field: 40)
        XCTAssertNotNil(node.bankBar)
        node.showBank(paid: bank.cap / 2, cap: bank.cap)
        XCTAssertEqual(node.bankFraction, 0.5, accuracy: 0.01)
        XCTAssertFalse(node.bankEmpty)
        node.showBank(paid: bank.cap, cap: bank.cap)
        XCTAssertTrue(node.bankEmpty)
        XCTAssertEqual(node.bankFraction, 1, accuracy: 0.001)
        XCTAssertLessThan(node.art.alpha, 1)

        var empty = tower
        empty.paid = bank.cap
        XCTAssertTrue(controller.isEmpty(empty))
        XCTAssertFalse(controller.isEmpty(tower))
        let watch = TowerNode(tower: Tower(id: 2, kind: .watch, cell: Cell(x: 1, y: 0), cooldownTicks: 0, spent: 1), field: 40)
        XCTAssertNil(watch.bankBar, "nur die Bank hat einen Balken")
    }

    func testSceneShowsPayoutsOverAWholeBank() throws {
        model = BattleModel(config: rich, seed: 1, autoplay: false)
        controller = BattleController(model: model, interactive: true)
        let scene = BattleScene(model: model)
        scene.controller = controller
        let frameTime = 1 / Double(config.simulation.ticksPerSecond)
        build(.bank, at: try XCTUnwrap(model.sim.map.buildableCells.first))
        var guardTicks = model.sim.ticks(bank.delay + bank.interval * Double(bank.cap / bank.payout + 2))
        while scene.fx.stats.empties == 0 && guardTicks > 0 {
            scene.frame(after: frameTime)
            guardTicks -= 1
        }
        XCTAssertEqual(scene.fx.stats.empties, 1, scene.fx.stats.summary)
        XCTAssertEqual(scene.fx.stats.payouts, (bank.cap + bank.payout - 1) / bank.payout, scene.fx.stats.summary)
        XCTAssertEqual(scene.fx.stats.coins, 0, "Bankgold fliegt nicht als Münzen; die gehören den Kills")
    }
}
