import XCTest
@testable import Oddlings

/// „Höchstens vier gleichzeitige Klänge derselben Art" (Rückmeldeliste).
final class SoundLimiterTests: XCTestCase {
    func testVoicesPerCueAreCapped() {
        var limiter = SoundLimiter()
        let mix = AudioStyle.mix(.enemyPop)
        var admitted = 0
        for step in 0..<20 where limiter.admit(.enemyPop, at: Double(step) * mix.spacing * 1.5, duration: 10) {
            admitted += 1
        }
        XCTAssertEqual(admitted, mix.voices)
    }

    func testSpacingDropsBurstsButNotOtherCues() {
        var limiter = SoundLimiter()
        XCTAssertTrue(limiter.admit(.hit, at: 0, duration: 0.01))
        XCTAssertFalse(limiter.admit(.hit, at: 0, duration: 0.01), "gleicher Augenblick")
        XCTAssertTrue(limiter.admit(.enemyPop, at: 0, duration: 0.01), "anderer Klang zählt eigen")
        XCTAssertTrue(limiter.admit(.hit, at: AudioStyle.mix(.hit).spacing, duration: 0.01))
    }

    func testVoiceFreesWhenItEnds() {
        var limiter = SoundLimiter()
        XCTAssertTrue(limiter.admit(.wave, at: 0, duration: 1))
        XCTAssertFalse(limiter.admit(.wave, at: 0.5, duration: 1), "Stimme belegt und zu dicht")
        XCTAssertTrue(limiter.admit(.wave, at: 5, duration: 1))
        limiter.reset()
        XCTAssertTrue(limiter.admit(.wave, at: 5, duration: 1), "nach Neustart frei")
    }
}
