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

    func testRoundTrip() throws {
        let save = SaveGame(progress: CampaignProgress(records: [MissionRecord(mission: "a", bestStars: 2)]), race: .elves)
        let decoded = try SaveGameCodec.decode(try SaveGameCodec.encode(save), campaign: campaign)
        XCTAssertEqual(decoded.save, save)
        XCTAssertEqual(decoded.dropped, [])
    }

    func testDropsUnknownEntriesOneByOne() throws {
        let decoded = try decode("""
        {"schemaVersion":1,"race":"goblins","progress":{"records":[
          {"mission":"a","bestStars":2},{"mission":"zz","bestStars":3},
          {"mission":"b","bestStars":9},{"mission":"a","bestStars":3}]}}
        """)
        XCTAssertEqual(decoded.save.progress.records, [MissionRecord(mission: "a", bestStars: 2)])
        XCTAssertNil(decoded.save.race)
        XCTAssertEqual(decoded.dropped, [.unknownMission("zz"), .starsOutOfRange(mission: "b", stars: 9),
                                         .duplicateMission("a"), .unknownRace("goblins")])
    }

    func testSchemaOutsideThisAppIsRefused() {
        XCTAssertThrowsError(try decode(#"{"schemaVersion":2}"#)) {
            XCTAssertEqual($0 as? SaveGameCodec.Failure, .newerSchema(2))
        }
        XCTAssertThrowsError(try decode(#"{"schemaVersion":0}"#)) {
            XCTAssertEqual($0 as? SaveGameCodec.Failure, .unknownSchema(0))
        }
        XCTAssertThrowsError(try decode("{kaputt")) {
            guard case .unreadable = $0 as? SaveGameCodec.Failure else { return XCTFail("\($0)") }
        }
    }

    func testMissingProgressIsAnEmptyStart() throws {
        XCTAssertEqual(try decode(#"{"schemaVersion":1}"#).save, SaveGame())
    }
}
