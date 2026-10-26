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
}
