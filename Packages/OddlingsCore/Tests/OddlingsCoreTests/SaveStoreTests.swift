import XCTest
@testable import OddlingsCore

final class SaveStoreTests: XCTestCase {
    private let campaign = CampaignConfig(id: "test", nodes: [
        CampaignNode(id: "a", kind: .main, mission: "m", position: Point(x: 0.1, y: 0.5)),
    ])
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SaveStoreTests-\(name.filter(\.isLetter))-\(ProcessInfo.processInfo.processIdentifier)")
        try? FileManager.default.removeItem(at: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func save(stars: Int) -> SaveGame {
        SaveGame(progress: CampaignProgress(records: [MissionRecord(mission: "a", bestStars: stars)]))
    }

    func testFreshWithoutFiles() {
        let loaded = SaveStore(directory: directory).load(campaign: campaign)
        XCTAssertEqual(loaded.source, .fresh)
        XCTAssertEqual(loaded.save, SaveGame())
        XCTAssertTrue(loaded.writable)
    }

    func testWriteThenReadAndPreviousVersionIsKept() throws {
        let store = SaveStore(directory: directory)
        try store.save(save(stars: 1))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.previousURL.path))
        try store.save(save(stars: 3))
        XCTAssertEqual(store.load(campaign: campaign), .init(save: save(stars: 3), source: .primary, writable: true, notes: []))
        let previous = try SaveGameCodec.decode(Data(contentsOf: store.previousURL), campaign: campaign)
        XCTAssertEqual(previous.save, save(stars: 1))
    }

    func testBrokenPrimaryFallsBackToPrevious() throws {
        let store = SaveStore(directory: directory)
        try store.save(save(stars: 2))
        try store.save(save(stars: 3))
        try Data("{halb geschri".utf8).write(to: store.primaryURL)
        let loaded = store.load(campaign: campaign)
        XCTAssertEqual(loaded.source, .previous)
        XCTAssertEqual(loaded.save, save(stars: 2))
        XCTAssertEqual(loaded.notes.count, 1)
    }

    func testBothBrokenStartsFresh() throws {
        let store = SaveStore(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: store.primaryURL)
        try Data("y".utf8).write(to: store.previousURL)
        let loaded = store.load(campaign: campaign)
        XCTAssertEqual(loaded.source, .fresh)
        XCTAssertEqual(loaded.notes.count, 2)
        XCTAssertTrue(loaded.writable)
    }

    func testOversizedFileIsNotRead() throws {
        let store = SaveStore(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(repeating: 0x20, count: SaveStore.maximumBytes + 1).write(to: store.primaryURL)
        let loaded = store.load(campaign: campaign)
        XCTAssertEqual(loaded.source, .fresh)
        XCTAssertTrue(loaded.notes.first?.contains("zu groß") == true, "\(loaded.notes)")
    }

    func testNewerSchemaIsNeitherReadNorOverwritten() throws {
        let store = SaveStore(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let newer = Data(#"{"schemaVersion":7,"progress":{"records":[]}}"#.utf8)
        try newer.write(to: store.primaryURL)
        let loaded = store.load(campaign: campaign)
        XCTAssertEqual(loaded.source, .fresh)
        XCTAssertFalse(loaded.writable)
        XCTAssertThrowsError(try store.save(save(stars: 1), allowed: loaded.writable)) {
            XCTAssertEqual($0 as? SaveStore.WriteError, .readOnly)
        }
        XCTAssertEqual(try Data(contentsOf: store.primaryURL), newer)
    }
}
