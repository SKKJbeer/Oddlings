import XCTest
@testable import Oddlings

final class AppSettingsTests: XCTestCase {
    func testVibrationIsOnUntilSwitchedOffAndRemembered() throws {
        let name = "AppSettingsTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        XCTAssertTrue(AppSettings.vibration(in: defaults), "ohne Eintrag an")
        AppSettings.setVibration(false, in: defaults)
        XCTAssertFalse(AppSettings.vibration(in: defaults))
        AppSettings.setVibration(true, in: defaults)
        XCTAssertTrue(AppSettings.vibration(in: defaults))
    }

    func testVolumesHaveDefaultsAreRememberedAndClamped() throws {
        let name = "AppSettingsTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        XCTAssertEqual(AppSettings.soundVolume(in: defaults), AudioStyle.defaultSound)
        XCTAssertEqual(AppSettings.musicVolume(in: defaults), AudioStyle.defaultMusic)
        AppSettings.setSoundVolume(0.3, in: defaults)
        AppSettings.setMusicVolume(0, in: defaults)
        XCTAssertEqual(AppSettings.soundVolume(in: defaults), 0.3)
        XCTAssertEqual(AppSettings.musicVolume(in: defaults), 0)
        // Von außen verändert (Sicherung, Profil): begrenzen bzw. verwerfen.
        defaults.set(7.5, forKey: AppSettings.soundKey)
        defaults.set("laut", forKey: AppSettings.musicKey)
        XCTAssertEqual(AppSettings.soundVolume(in: defaults), 1)
        XCTAssertEqual(AppSettings.musicVolume(in: defaults), AudioStyle.defaultMusic)
    }
}
