import XCTest
@testable import OddlingsCore

final class StarRatingTests: XCTestCase {
    private let thresholds = StarThresholds(two: 15, three: 20)

    func testThresholdsAreInclusive() {
        XCTAssertEqual(StarRating.stars(outcome: .won, livesLeft: 20, thresholds: thresholds), 3)
        XCTAssertEqual(StarRating.stars(outcome: .won, livesLeft: 19, thresholds: thresholds), 2)
        XCTAssertEqual(StarRating.stars(outcome: .won, livesLeft: 15, thresholds: thresholds), 2)
        XCTAssertEqual(StarRating.stars(outcome: .won, livesLeft: 14, thresholds: thresholds), 1)
        XCTAssertEqual(StarRating.stars(outcome: .won, livesLeft: 1, thresholds: thresholds), 1)
    }

    func testLossGivesNoStarsAndWinWithoutThresholdsGivesOne() {
        XCTAssertEqual(StarRating.stars(outcome: .lost, livesLeft: 20, thresholds: thresholds), 0)
        XCTAssertEqual(StarRating.stars(outcome: .won, livesLeft: 3, thresholds: nil), 1)
    }

    func testMissionOneHasThresholdsWithinItsLives() throws {
        let config = try BalanceConfig.missionOne()
        let stars = try XCTUnwrap(config.mission.stars)
        XCTAssertLessThanOrEqual(stars.three, config.mission.fortressLives)
    }

    func testValidationRejectsThresholdsOutOfOrder() {
        for bad in [StarThresholds(two: 0, three: 5), StarThresholds(two: 8, three: 7), StarThresholds(two: 5, three: 11)] {
            var config = TestConfig.make()
            config.mission.stars = bad
            XCTAssertEqual(config.issues(), [ConfigIssue(field: "mission.stars", rule: .starsOutOfOrder)], "\(bad)")
        }
        var good = TestConfig.make()
        good.mission.stars = StarThresholds(two: 5, three: 10)
        XCTAssertEqual(good.issues(), [])
    }
}
