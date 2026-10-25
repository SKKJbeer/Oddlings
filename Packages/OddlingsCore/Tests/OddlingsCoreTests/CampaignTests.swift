import XCTest
@testable import OddlingsCore

final class CampaignTests: XCTestCase {
    /// Kleine Region mit Gabelung und Nebenmission, unabhängig von region-01.json.
    private func region(_ nodes: [CampaignNode]? = nil) -> CampaignConfig {
        CampaignConfig(id: "test", nodes: nodes ?? [
            CampaignNode(id: "a", kind: .main, mission: "m", position: Point(x: 0.1, y: 0.5)),
            CampaignNode(id: "b", kind: .main, mission: "m", position: Point(x: 0.3, y: 0.5), requires: ["a"]),
            CampaignNode(id: "c1", kind: .main, mission: "m", position: Point(x: 0.5, y: 0.3), requires: ["b"]),
            CampaignNode(id: "c2", kind: .main, position: Point(x: 0.5, y: 0.7), requires: ["b"]),
            CampaignNode(id: "boss", kind: .boss, mission: "m", position: Point(x: 0.9, y: 0.5),
                         requires: ["c1", "c2"], requiresAny: true),
            CampaignNode(id: "side", kind: .side, mission: "m", position: Point(x: 0.2, y: 0.9), stars: 4),
        ])
    }

    private func anyMission(_: String) throws(ConfigError) -> BalanceConfig { TestConfig.make() }

    private func progress(_ pairs: [(String, Int)]) -> CampaignProgress {
        CampaignProgress(records: pairs.map { MissionRecord(mission: $0.0, bestStars: $0.1) })
    }

    func testRegionOneLoadsAndOnlyMissionOneIsBuilt() throws {
        let config = try CampaignConfig.regionOne()
        XCTAssertEqual(config.nodes.count, 11, "sieben Hauptmissionen mit zwei Wegen (9 Knoten) und zwei Nebenmissionen")
        XCTAssertEqual(config.nodes.filter { $0.kind == .side }.compactMap(\.stars), [6, 15])
        XCTAssertEqual(config.nodes.filter { $0.kind == .boss }.map(\.id), ["m7"])
        XCTAssertEqual(config.nodes.compactMap(\.mission), ["mvp-mission-01"])
    }

    func testRegionOneStatesAtStartAndAfterMissionOne() throws {
        let config = try CampaignConfig.regionOne()
        let fresh = CampaignProgress()
        XCTAssertEqual(config.state(of: try XCTUnwrap(config.node("m1")), progress: fresh), .open)
        XCTAssertEqual(config.state(of: try XCTUnwrap(config.node("m2")), progress: fresh), .locked(.after(["m1"])))
        XCTAssertEqual(config.state(of: try XCTUnwrap(config.node("n1")), progress: fresh), .locked(.stars(6)))
        let won = fresh.recording(stars: 3, for: "m1")
        XCTAssertEqual(config.state(of: try XCTUnwrap(config.node("m1")), progress: won), .completed(stars: 3))
        XCTAssertEqual(config.state(of: try XCTUnwrap(config.node("m2")), progress: won), .inPreparation)
        XCTAssertEqual(config.continueNode(progress: fresh)?.id, "m1")
        XCTAssertEqual(config.continueNode(progress: won)?.id, "m1", "nichts Neues offen: zurück zur gewonnenen Mission")
    }

    func testForkOpensBossAfterEitherPath() {
        let config = region()
        let boss = config.nodes[4]
        XCTAssertEqual(config.state(of: boss, progress: progress([("a", 1), ("b", 1)])), .locked(.after(["c1", "c2"])))
        XCTAssertEqual(config.state(of: boss, progress: progress([("a", 1), ("b", 1), ("c1", 2)])), .open)
        XCTAssertEqual(config.state(of: config.nodes[3], progress: progress([("a", 1), ("b", 1)])), .inPreparation)
    }

    func testSideMissionOpensAtStarTotal() {
        let config = region()
        let side = config.nodes[5]
        XCTAssertEqual(config.state(of: side, progress: progress([("a", 3)])), .locked(.stars(4)))
        XCTAssertEqual(config.state(of: side, progress: progress([("a", 3), ("b", 1)])), .open)
    }

    func testContinueNodeIsFirstOpenUnwonInFileOrder() {
        let config = region()
        XCTAssertEqual(config.continueNode(progress: progress([("a", 2)]))?.id, "b")
        XCTAssertEqual(config.continueNode(progress: progress([("a", 2), ("b", 1)]))?.id, "c1")
    }

    func testProgressKeepsBestAndIgnoresLoss() {
        let start = progress([("a", 2)])
        XCTAssertEqual(start.recording(stars: 1, for: "a"), start)
        XCTAssertEqual(start.recording(stars: 0, for: "b"), start)
        XCTAssertEqual(start.recording(stars: 3, for: "a").stars(for: "a"), 3)
        XCTAssertEqual(start.recording(stars: 1, for: "b").totalStars, 3)
    }

    func testValidationFindsEachProblem() {
        let at = Point(x: 0.5, y: 0.5)
        func issues(_ nodes: [CampaignNode]) -> [CampaignIssue.Rule] {
            region(nodes).issues(loadMission: anyMission).map(\.rule)
        }
        XCTAssertEqual(region().issues(loadMission: anyMission), [])
        XCTAssertEqual(issues([.init(id: "a", kind: .main, position: at), .init(id: "a", kind: .main, position: at)]),
                       [.duplicateID])
        XCTAssertEqual(issues([.init(id: "a", kind: .main, position: at),
                               .init(id: "b", kind: .main, position: at, requires: ["x"])]),
                       [.unknownRequirement("x")])
        XCTAssertEqual(issues([.init(id: "a", kind: .main, position: at, requires: ["b"]),
                               .init(id: "b", kind: .main, position: at, requires: ["a"])]),
                       [.noStart, .cycle, .cycle])
        XCTAssertEqual(issues([.init(id: "a", kind: .main, position: Point(x: 1.2, y: 0))]), [.positionOutsideMap])
        XCTAssertEqual(issues([.init(id: "a", kind: .side, position: at, stars: 0)]), [.starsNotPositive])
        let broken = region([.init(id: "a", kind: .main, mission: "fehlt", position: at)])
            .issues(loadMission: { (name: String) throws(ConfigError) -> BalanceConfig in throw .resourceMissing(name) })
        XCTAssertEqual(broken.map(\.rule), [.missionInvalid("Konfiguration fehlt nicht gefunden")])
    }

    func testLoadRejectsInvalidRegion() {
        let json = #"{"id":"x","nodes":[{"id":"a","kind":"main","position":[0.5,0.5],"requires":["a"]}]}"#
        XCTAssertThrowsError(try CampaignConfig.load(from: Data(json.utf8), loadMission: anyMission)) { error in
            guard case CampaignError.invalid = error else { return XCTFail("\(error)") }
        }
    }
}
