import XCTest
@testable import Oddlings

/// Schreibt mit, was der Director spielen würde, statt es zu spielen.
@MainActor
final class RecordingOutput: SoundOutput {
    var played: [(file: String, gain: Float, rate: Float)] = []
    var music: [(file: String, loops: Bool, gain: Float)] = []
    var musicGain: Float = 0
    var soundVolume: Float = 0
    var suspended = false
    var free = true

    func duration(of file: String) -> Double? { 0.2 }
    func play(file: String, gain: Float, rate: Float) -> Bool {
        guard free else { return false }
        played.append((file, gain, rate))
        return true
    }
    func setSoundVolume(_ volume: Float) { soundVolume = volume }
    func playMusic(file: String, loops: Bool, gain: Float, fade: TimeInterval) {
        music.append((file, loops, gain))
        musicGain = gain
    }
    func setMusicGain(_ gain: Float, fade: TimeInterval) { musicGain = gain }
    func stopMusic(fade: TimeInterval) {}
    func suspend() { suspended = true }
    func resume() { suspended = false }
}

@MainActor
final class AudioDirectorTests: XCTestCase {
    private var now = 0.0

    private func director(sound: Double = 0.5, music: Double = 0.5) throws -> (AudioDirector, RecordingOutput) {
        let name = "AudioDirectorTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        AppSettings.setSoundVolume(sound, in: defaults)
        AppSettings.setMusicVolume(music, in: defaults)
        let output = RecordingOutput()
        return (AudioDirector(output: output, defaults: defaults, clock: { [unowned self] in now }), output)
    }

    func testVolumesComeFromTheSettings() throws {
        let (audio, output) = try director(sound: 0.25, music: 0.5)
        XCTAssertEqual(output.soundVolume, 0.25)
        audio.setMood(.battle)
        XCTAssertEqual(output.musicGain, AudioStyle.musicGain * 0.5, accuracy: 0.001)
        audio.setMusicVolume(2)
        XCTAssertEqual(audio.musicVolume, 1, "begrenzt")
    }

    func testVariantsAlternateAndPitchSpreads() throws {
        let (audio, output) = try director()
        for _ in 0..<3 {
            audio.play(.fired(.watch, links: 1, combo: false))
            now += 1
        }
        XCTAssertEqual(output.played.map(\.file), ["watch_shot_1.caf", "watch_shot_2.caf", "watch_shot_3.caf"])
        XCTAssertEqual(Set(output.played.map(\.rate)).count, 3, "Tonhöhe streut")
        let semitones = AudioStyle.mix(.watchShot).spread
        for entry in output.played {
            XCTAssertEqual(log2(entry.rate) * 12, 0, accuracy: semitones + 0.001)
        }
        XCTAssertEqual(audio.stats.count(.watchShot), 3)
    }

    func testBurstsAreThinnedAndCounted() throws {
        let (audio, output) = try director()
        for _ in 0..<10 { audio.play(.damaged) }
        XCTAssertEqual(output.played.count, 1, "im selben Augenblick nur einer")
        XCTAssertEqual(audio.stats.dropped, 9)
        output.free = false
        now += 1
        audio.play(.killed)
        XCTAssertEqual(audio.stats.count(.enemyPop), 0, "kein Spieler frei")
    }

    func testWatchingHasNoUserSounds() throws {
        let (audio, output) = try director()
        audio.play(.user(.callWave), interactive: false)
        XCTAssertTrue(output.played.isEmpty)
        audio.play(.user(.callWave))
        XCTAssertEqual(output.played.map(\.file), ["ui_confirm_1.caf"])
    }

    func testMusicFollowsTheBattle() throws {
        let (audio, output) = try director()
        audio.setMood(.menu)
        audio.startBattle()
        audio.play(.waveStarted(index: 0, count: 2))
        audio.play(.waveStarted(index: 1, count: 2))
        audio.play(.missionEnded(won: true))
        audio.startBattle()
        XCTAssertEqual(output.music.map(\.file),
                       ["music_menu.m4a", "music_battle.m4a", "music_final_wave.m4a", "music_victory.m4a", "music_battle.m4a"])
        XCTAssertEqual(output.music.map(\.loops), [true, true, true, false, true])
        audio.setMood(.battle)
        XCTAssertEqual(output.music.count, 5, "gleiche Lage beginnt nicht von vorn")
    }

    func testPauseDucksTheMusic() throws {
        let (audio, output) = try director(music: 1)
        audio.setMood(.battle)
        audio.setPaused(true)
        XCTAssertEqual(output.musicGain, AudioStyle.musicGain * AudioStyle.pauseDuck, accuracy: 0.001)
        audio.setPaused(false)
        XCTAssertEqual(output.musicGain, AudioStyle.musicGain, accuracy: 0.001)
        audio.suspend()
        XCTAssertTrue(output.suspended)
        audio.resume()
        XCTAssertFalse(output.suspended)
    }
}
