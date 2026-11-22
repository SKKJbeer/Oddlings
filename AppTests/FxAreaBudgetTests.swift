import XCTest
@testable import Oddlings

/// Effektbudget je Bereich (A-5 Teil 2, D-181): höchstens zwei große Wolken
/// voll übereinander, jede weitere gedämpft; Längen in Feldern.
final class FxAreaBudgetTests: XCTestCase {
    private func budget() -> FxAreaBudget { FxAreaBudget(limit: 2, dampedShare: 0.34, dampedAlpha: 0.5) }

    func testThirdOverlappingCloudIsDamped() {
        var budget = budget()
        XCTAssertEqual(budget.claim(x: 5, y: 3, radius: 1.5, now: 0, life: 1), .full)
        XCTAssertEqual(budget.claim(x: 5.5, y: 3, radius: 1.5, now: 0.1, life: 1), .full)
        XCTAssertEqual(budget.claim(x: 5.2, y: 3.4, radius: 1.5, now: 0.2, life: 1), .damped(share: 0.34, alpha: 0.5))
        XCTAssertEqual(budget.active(at: 0.2), 3, "gedämpfte Wolken zählen mit")
    }

    func testDistantCloudsPlayFull() {
        var budget = budget()
        for index in 0..<6 {
            XCTAssertEqual(budget.claim(x: Double(index) * 4, y: 0, radius: 1.5, now: 0, life: 1), .full, "\(index)")
        }
    }

    func testFinishedCloudsNoLongerCount() {
        var budget = budget()
        _ = budget.claim(x: 0, y: 0, radius: 1, now: 0, life: 0.5)
        _ = budget.claim(x: 0, y: 0, radius: 1, now: 0, life: 0.5)
        XCTAssertEqual(budget.claim(x: 0, y: 0, radius: 1, now: 0.6, life: 0.5), .full)
        XCTAssertEqual(budget.active(at: 0.6), 1)
    }

    func testResetClearsEverything() {
        var budget = budget()
        _ = budget.claim(x: 0, y: 0, radius: 1, now: 0, life: 5)
        _ = budget.claim(x: 0, y: 0, radius: 1, now: 0, life: 5)
        budget.reset()
        XCTAssertEqual(budget.claim(x: 0, y: 0, radius: 1, now: 0, life: 5), .full)
    }

    func testDampedGrantKeepsAtLeastOneParticle() {
        let damped = FxAreaBudget.Grant.damped(share: 0.34, alpha: 0.5)
        XCTAssertEqual(damped.count(12), 4)
        XCTAssertEqual(damped.count(1), 1)
        XCTAssertEqual(FxAreaBudget.Grant.full.count(12), 12)
        XCTAssertEqual(damped.alpha, 0.5)
        XCTAssertEqual(FxAreaBudget.Grant.full.alpha, 1)
    }
}
