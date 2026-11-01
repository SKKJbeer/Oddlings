import OddlingsCore
import XCTest
@testable import Oddlings

/// Die Tabelle „Klang je Ereignis" aus docs/konzepte/p2-3-ton-und-musik.md.
final class SoundMapTests: XCTestCase {
    private func cues(_ moment: SoundMoment) -> [SoundCue] { SoundMap.requests(for: moment).map(\.cue) }

    func testEveryMomentButTheEndHasASound() {
        let moments: [SoundMoment] = [
            .built, .sold, .rejected, .fired(.watch, links: 1, combo: false), .fired(.lightning, links: 1, combo: false),
            .fired(.spore, links: 3, combo: false), .damaged, .slowed, .killed, .leaked,
            .waveStarted(index: 0, count: 5), .abilityCast, .abilityImpact(moon: false), .abilityImpact(moon: true),
            .wallRaised, .wallFell, .user(.selectCell), .user(.callWave), .user(.cannotAfford),
        ]
        for moment in moments { XCTAssertFalse(cues(moment).isEmpty, "\(moment) klingt") }
        // Das Ende trägt die Musik, nicht ein Klang.
        XCTAssertTrue(cues(.missionEnded(won: true)).isEmpty)
    }

    func testEachTowerHasItsOwnVoice() {
        let voices = TowerKind.allCases.map { cues(.fired($0, links: 1, combo: false)) }
        XCTAssertEqual(Set(voices.map { $0.first }).count, TowerKind.allCases.count)
    }

    func testSporeSparkHasItsOwnSound() {
        XCTAssertEqual(cues(.fired(.lightning, links: 2, combo: true)), [.boltShot, .combo])
        XCTAssertEqual(cues(.fired(.lightning, links: 2, combo: false)), [.boltShot])
    }

    func testLightningRisesWithEachLinkUpToALimit() {
        XCTAssertEqual(SoundMap.boltPitch(links: 1), 0)
        XCTAssertLessThan(SoundMap.boltPitch(links: 2), SoundMap.boltPitch(links: 3))
        XCTAssertEqual(SoundMap.boltPitch(links: 50), SoundMap.boltPitch(links: AudioStyle.boltMaxSteps + 1))
    }

    func testKillPopsAndPays() {
        XCTAssertEqual(cues(.killed), [.enemyPop, .coin])
    }

    func testLastWaveAndEndChangeTheMusic() {
        XCTAssertNil(SoundMap.mood(after: .waveStarted(index: 0, count: 3)))
        XCTAssertEqual(SoundMap.mood(after: .waveStarted(index: 2, count: 3)), .finalWave)
        XCTAssertEqual(SoundMap.mood(after: .missionEnded(won: true)), .victory)
        XCTAssertEqual(SoundMap.mood(after: .missionEnded(won: false)), .defeat)
        XCTAssertNil(SoundMap.mood(after: .built))
    }

    func testFileNamesFollowTheCue() {
        XCTAssertEqual(SoundCue.watchShot.stem, "watch_shot")
        XCTAssertEqual(SoundCue.uiTap.files, ["ui_tap_1.caf", "ui_tap_2.caf"])
        XCTAssertFalse(MusicMood.victory.loops)
        XCTAssertTrue(MusicMood.battle.loops)
    }
}
