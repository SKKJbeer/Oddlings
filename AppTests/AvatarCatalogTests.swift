import OddlingsCore
import XCTest
@testable import Oddlings

/// Porträts und Namensvorschläge des Avatar-Aufbaus (R-5).
final class AvatarCatalogTests: XCTestCase {
    func testEveryRaceHasThreePortraitsWithValidIDs() {
        for race in Race.allCases {
            let portraits = AvatarPortraits.of(race)
            XCTAssertEqual(portraits.count, 3, "\(race)")
            for portrait in portraits {
                XCTAssertTrue(Avatar.isValidPortrait(portrait.id), portrait.id)
                XCTAssertEqual(portrait.race, race)
            }
        }
        let ids = AvatarPortraits.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Kennungen sind eindeutig")
    }

    /// Jedes Porträt ist gemalt und quadratisch: `PortraitView` füllt einen Kreis
    /// mit `scaledToFill`, ein Hochformat würde Stirn oder Kinn abschneiden.
    /// 192 px reichen für 64 pt bei dreifacher Auflösung.
    func testEveryPortraitIsPaintedAndSquare() throws {
        for portrait in AvatarPortraits.all {
            let picture = try XCTUnwrap(UITheme.image(portrait.imageName), portrait.imageName)
            let pixels = CGSize(width: picture.size.width * picture.scale, height: picture.size.height * picture.scale)
            XCTAssertEqual(pixels.width, pixels.height, portrait.imageName)
            XCTAssertGreaterThanOrEqual(pixels.width, 192, portrait.imageName)
        }
    }

    func testUnknownOrForeignPortraitFallsBackToTheFirstOfTheRace() {
        XCTAssertEqual(AvatarPortraits.resolve("elf-3", race: .elves).id, "elf-3")
        XCTAssertEqual(AvatarPortraits.resolve("elf-9", race: .elves).id, AvatarPortraits.of(.elves)[0].id)
        XCTAssertEqual(AvatarPortraits.resolve("elf-2", race: .dwarves).id, AvatarPortraits.of(.dwarves)[0].id,
                       "kein Elfenbild für einen Zwerg")
    }

    func testSuggestedNamesPassTheCheck() {
        for race in Race.allCases {
            let names = AvatarTexts.suggestions(race)
            XCTAssertGreaterThan(names.count, 1, "\(race): Würfeln braucht eine Auswahl")
            for name in names { XCTAssertEqual(Avatar.validName(name), name, name) }
        }
    }
}
