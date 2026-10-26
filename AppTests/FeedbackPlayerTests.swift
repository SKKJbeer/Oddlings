import OddlingsCore
import XCTest
@testable import Oddlings

/// Zuordnung Handlung bzw. Ereignis → Haptik (07-ui-ux.md, Abschnitt 5).
@MainActor
final class FeedbackPlayerTests: XCTestCase {
    func testActions() {
        XCTAssertEqual(FeedbackPlayer.haptic(for: .selectCell), .selection)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .preview), .selection)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .armSell), .selection)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .callWave), .heavy)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .cannotAfford), .warning)
    }

    func testEventsOfTheTable() {
        XCTAssertEqual(FeedbackPlayer.haptic(for: .towerBuilt(id: 1)), .medium)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .towerSold(id: 1, refund: 10)), .light)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .commandRejected(.callNextWave, reason: .notEnoughGold)), .warning)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .enemyLeaked(id: 1, damage: 1)), .warning)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .missionEnded(won: true)), .success)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .missionEnded(won: false)), .error)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .abilityCast(center: Point(x: 1, y: 1), impactTick: 5)), .light)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .abilityImpact(center: Point(x: 1, y: 1), hits: [])), .heavy)
        XCTAssertEqual(FeedbackPlayer.haptic(for: .barrierRaised(distance: 3, untilTick: 9)), .heavy)
        XCTAssertNil(FeedbackPlayer.haptic(for: .barrierFell), "das Ende der Mauer ist keine Handlung")
    }

    /// Treffer und Tode kommen in Mengen; sie dürfen die eigene Handlung nicht übertönen.
    func testCombatStaysSilent() {
        let silent: [Event] = [.towerFired(towerID: 1, targets: [2]), .enemyDamaged(id: 2, amount: 1),
                               .enemySlowed(id: 2), .enemyKilled(id: 2, reward: 3),
                               .waveStarted(index: 0), .enemySpawned(id: 3)]
        for event in silent { XCTAssertNil(FeedbackPlayer.haptic(for: event), "\(event)") }
    }
}
