import UIKit
import XCTest
@testable import Oddlings

/// Die Schriften aus D-032 liegen im Bündel und lassen sich laden. Fehlt eine,
/// fiele SwiftUI still auf die Systemschrift zurück; das soll hier auffallen.
@MainActor
final class AppFontsTests: XCTestCase {
    func testEveryFontLoads() {
        AppFonts.register()
        for name in AppFonts.all {
            XCTAssertNil(UIFont(name: name, size: 17), "\(name) fehlt im Bündel")
        }
    }

    func testSceneUsesDisplayFont() {
        XCTAssertNotEqual(BattleStyle.font, AppFonts.display)
    }
}
