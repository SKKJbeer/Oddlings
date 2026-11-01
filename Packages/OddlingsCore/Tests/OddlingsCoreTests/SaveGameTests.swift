import XCTest
@testable import OddlingsCore

final class SaveGameTests: XCTestCase {
    private let campaign = CampaignConfig(id: "test", nodes: [
        CampaignNode(id: "a", kind: .main, mission: "m", position: Point(x: 0.1, y: 0.5)),
        CampaignNode(id: "b", kind: .main, position: Point(x: 0.3, y: 0.5), requires: ["a"]),
    ])

    private func decode(_ json: String) throws -> SaveGameCodec.Decoded {
        try SaveGameCodec.decode(Data(json.utf8), campaign: campaign)
    }

    private func avatar(_ race: Race = .elves, name: String = "Lyra", portrait: String = "elf-2") throws -> Avatar {
        try XCTUnwrap(Avatar(race: race, name: name, portrait: portrait))
    }

    func testRoundTrip() throws {
        let save = SaveGame(progress: CampaignProgress(records: [MissionRecord(mission: "a", bestStars: 2)]),
                            avatar: try avatar())
        let decoded = try SaveGameCodec.decode(try SaveGameCodec.encode(save), campaign: campaign)
        XCTAssertEqual(decoded.save, save)
        XCTAssertEqual(decoded.dropped, [])
    }

    /// R-6: Die Talentwahl übersteht Speichern und Laden; eine kaputte Wahl
    /// kostet nur die Wahl, nicht den Avatar.
    func testTalentChoiceSurvivesTheSaveFile() throws {
        var lyra = try avatar()
        lyra.talents = [.b, .a]
        let save = SaveGame(progress: CampaignProgress(), avatar: lyra)
        XCTAssertEqual(try SaveGameCodec.decode(try SaveGameCodec.encode(save), campaign: campaign).save.avatar?.talents,
                       [.b, .a])
        for broken in [#"["b","c"]"#, #""b""#, #"[1]"#] {
            let decoded = try decode(#"{"schemaVersion":2,"avatar":{"race":"elves","name":"Lyra","portrait":"elf-1","talents":"#
                                     + broken + "}}")
            XCTAssertEqual(decoded.save.avatar?.name, "Lyra", broken)
            XCTAssertEqual(decoded.save.avatar?.talents, [], broken)
        }
    }

    func testDropsUnknownEntriesOneByOne() throws {
        let decoded = try decode("""
        {"schemaVersion":2,"avatar":{"race":"goblins","name":"Grok","portrait":"elf-1"},"progress":{"records":[
          {"mission":"a","bestStars":2},{"mission":"zz","bestStars":3},
          {"mission":"b","bestStars":9},{"mission":"a","bestStars":3}]}}
        """)
        XCTAssertEqual(decoded.save.progress.records, [MissionRecord(mission: "a", bestStars: 2)])
        XCTAssertNil(decoded.save.avatar)
        XCTAssertEqual(decoded.dropped, [.unknownMission("zz"), .starsOutOfRange(mission: "b", stars: 9),
                                         .duplicateMission("a"), .unknownRace("goblins")])
    }

    func testSchemaOutsideThisAppIsRefused() {
        XCTAssertThrowsError(try decode(#"{"schemaVersion":3}"#)) {
            XCTAssertEqual($0 as? SaveGameCodec.Failure, .newerSchema(3))
        }
        XCTAssertThrowsError(try decode(#"{"schemaVersion":0}"#)) {
            XCTAssertEqual($0 as? SaveGameCodec.Failure, .unknownSchema(0))
        }
        XCTAssertThrowsError(try decode("{kaputt")) {
            guard case .unreadable = $0 as? SaveGameCodec.Failure else { return XCTFail("\($0)") }
        }
    }

    func testMissingProgressIsAnEmptyStart() throws {
        XCTAssertEqual(try decode(#"{"schemaVersion":2}"#).save, SaveGame())
    }

    /// R-5: Schema 1 kannte nur das Volk. Der Fortschritt bleibt, der Avatar
    /// wird einmal neu aufgebaut, und geschrieben wird Schema 2.
    func testSchemaOneKeepsProgressAndAsksForAnAvatar() throws {
        for race in [#","race":"elves""#, #","race":"goblins""#, ""] {
            let decoded = try decode("""
            {"schemaVersion":1\(race),"progress":{"records":[{"mission":"a","bestStars":3}]}}
            """)
            XCTAssertEqual(decoded.save.progress.records, [MissionRecord(mission: "a", bestStars: 3)], race)
            XCTAssertNil(decoded.save.avatar, race)
            XCTAssertEqual(decoded.save.schemaVersion, 2)
            XCTAssertEqual(decoded.dropped, [], "das alte Volk ist kein Fehler: \(race)")
            let written = String(decoding: try SaveGameCodec.encode(decoded.save), as: UTF8.self)
            XCTAssertTrue(written.contains(#""schemaVersion" : 2"#), written)
        }
    }

    /// Was von außen kommt, wird geprüft: Ein kaputter Avatar kostet den Avatar,
    /// nie den Fortschritt.
    func testInvalidAvatarIsDroppedButProgressStays() throws {
        let bad = [#"{"race":"elves","name":"   ","portrait":"elf-1"}"#,
                   #"{"race":"elves","name":"Ein viel zu langer Name","portrait":"elf-1"}"#,
                   #"{"race":"elves","name":"Ly\u0007ra","portrait":"elf-1"}"#,
                   #"{"race":"elves","name":"Lyra","portrait":"../../geheim"}"#,
                   #"{"race":"elves","name":"Lyra"}"#,
                   #"{"name":"Lyra","portrait":"elf-1"}"#]
        for avatar in bad {
            let decoded = try decode("""
            {"schemaVersion":2,"avatar":\(avatar),"progress":{"records":[{"mission":"a","bestStars":1}]}}
            """)
            XCTAssertNil(decoded.save.avatar, avatar)
            XCTAssertEqual(decoded.dropped, [.invalidAvatar], avatar)
            XCTAssertEqual(decoded.save.progress.records, [MissionRecord(mission: "a", bestStars: 1)], avatar)
        }
    }

    func testNameIsTrimmedAndChecked() throws {
        XCTAssertEqual(Avatar.validName("  Grimbold  "), "Grimbold")
        XCTAssertEqual(Avatar.validName(String(repeating: "ä", count: Avatar.maxNameLength))?.count, Avatar.maxNameLength)
        XCTAssertNil(Avatar.validName(String(repeating: "a", count: Avatar.maxNameLength + 1)))
        XCTAssertNil(Avatar.validName(""))
        XCTAssertNil(Avatar.validName("Grim\nbold"))
        XCTAssertNil(Avatar.validName("Grim\u{0}bold"))
        XCTAssertEqual(try avatar(name: " Lyra ").name, "Lyra")
        XCTAssertTrue(Avatar.isValidPortrait("dwarf-3"))
        XCTAssertFalse(Avatar.isValidPortrait("Dwarf-3"))
        XCTAssertFalse(Avatar.isValidPortrait(""))
        XCTAssertFalse(Avatar.isValidPortrait("dwarf/3"))
        XCTAssertNil(Avatar(race: .dwarves, name: "Grim", portrait: "a b"))
    }
}
