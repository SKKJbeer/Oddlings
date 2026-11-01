import AVFoundation
import XCTest
@testable import Oddlings

/// Jede Datei, die `AudioStyle` und `MusicMood` nennen, liegt im Bündel und
/// lässt sich lesen. Gegenstück zu tools/ton/ton_pruefen.py, das Herkunft und
/// Lizenz prüft.
final class AudioAssetTests: XCTestCase {
    private let bundle = Bundle(for: AudioDirector.self)

    func testEverySoundIsBundledAsShortMono() throws {
        for cue in SoundCue.allCases {
            for file in cue.files {
                let url = try XCTUnwrap(bundle.url(forResource: file, withExtension: nil), file)
                let audio = try AVAudioFile(forReading: url)
                XCTAssertEqual(audio.processingFormat.channelCount, 1, file)
                XCTAssertEqual(audio.processingFormat.sampleRate, 44_100, file)
                let seconds = Double(audio.length) / audio.processingFormat.sampleRate
                XCTAssertGreaterThan(seconds, 0.02, file)
                XCTAssertLessThan(seconds, 2, "\(file) ist ein Klang, kein Stück")
            }
        }
    }

    func testEveryMoodHasMusic() throws {
        for mood in MusicMood.allCases {
            let url = try XCTUnwrap(bundle.url(forResource: mood.file, withExtension: nil), mood.file)
            let player = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(player.duration, 20, mood.file)
        }
    }
}
