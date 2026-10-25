import Foundation
import Testing
@testable import OddlingsCore

@Suite("Konfiguration laden")
struct LoadingTests {
    @Test("Mission 1 lädt und ist gültig")
    func missionOneLoads() throws {
        let config = try BalanceConfig.missionOne()
        #expect(config.mission.id == "mission-01")
        #expect(config.simulation.ticksPerSecond == 30)
        #expect(config.waves.count == 10)
        #expect(config.map.path.count == 8)
        #expect(config.towers[.lightning]?.chainJumps == 4)
        #expect(config.issues().isEmpty)
    }

    @Test("Kaputtes JSON wird als unlesbar gemeldet")
    func brokenJSON() {
        #expect(throws: ConfigError.self) { try BalanceConfig.load(from: Data("{".utf8)) }
        do {
            _ = try BalanceConfig.load(from: Data("{".utf8))
        } catch {
            guard case .unreadable = error else { Issue.record("erwartet unreadable, war \(error)"); return }
        }
    }

    @Test("Unbekannter Turmtyp wird als unlesbar gemeldet")
    func unknownTowerKind() throws {
        var json = try missionOneJSON()
        var towers = json["towers"] as! [String: Any]
        towers["bank"] = towers["watch"]
        json["towers"] = towers
        let data = try JSONSerialization.data(withJSONObject: json)
        do {
            _ = try BalanceConfig.load(from: data)
            Issue.record("bank ist kein Turm des MVP und darf nicht durchgehen")
        } catch {
            guard case .unreadable = error else { Issue.record("erwartet unreadable, war \(error)"); return }
        }
    }

    @Test("Punkt mit drei Koordinaten wird abgelehnt")
    func pointWithThreeCoordinates() throws {
        var json = try missionOneJSON()
        var map = json["map"] as! [String: Any]
        map["path"] = [[0, 0, 0], [1, 1]]
        json["map"] = map
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: ConfigError.self) { try BalanceConfig.load(from: data) }
    }

    @Test("Ungültige Werte kommen mit Ort aus load heraus")
    func loadReportsIssues() throws {
        var json = try missionOneJSON()
        var mission = json["mission"] as! [String: Any]
        mission["fortressLives"] = 0
        json["mission"] = mission
        let data = try JSONSerialization.data(withJSONObject: json)
        do {
            _ = try BalanceConfig.load(from: data)
            Issue.record("fortressLives 0 darf nicht durchgehen")
        } catch {
            #expect(error == .invalid([ConfigIssue(field: "mission.fortressLives", rule: .mustBePositive)]))
        }
    }

    private func missionOneJSON() throws -> [String: Any] {
        let url = try #require(Bundle.module.url(forResource: "mvp-mission-01", withExtension: "json", subdirectory: "Balance"))
        return try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
    }
}

/// Je Regel ein Negativfall: gültige Mission 1 nehmen, genau einen Wert
/// verderben, genau diesen Verstoß erwarten.
@Suite("Validierung")
struct ValidationTests {
    let valid: BalanceConfig

    init() throws { valid = try BalanceConfig.missionOne() }

    private func expectOnly(_ field: String, _ rule: ConfigIssue.Rule, _ change: (inout BalanceConfig) -> Void) {
        var config = valid
        change(&config)
        #expect(config.issues() == [ConfigIssue(field: field, rule: rule)])
    }

    @Test func ticksPerSecond() { expectOnly("simulation.ticksPerSecond", .mustBePositive) { $0.simulation.ticksPerSecond = 0 } }
    @Test func fortressLives() { expectOnly("mission.fortressLives", .mustBePositive) { $0.mission.fortressLives = 0 } }
    @Test func startGold() { expectOnly("mission.startGold", .mustNotBeNegative) { $0.mission.startGold = -1 } }
    @Test func firstWaveDelay() { expectOnly("mission.firstWaveDelay", .mustNotBeNegative) { $0.mission.firstWaveDelay = -1 } }
    @Test func timeBetweenWaves() { expectOnly("mission.timeBetweenWaves", .mustNotBeNegative) { $0.mission.timeBetweenWaves = -0.5 } }
    @Test func refundAboveOne() { expectOnly("mission.sellRefundRate", .mustBeRate) { $0.mission.sellRefundRate = 1.2 } }
    @Test func refundZeroIsAllowed() {
        var config = valid
        config.mission.sellRefundRate = 0
        #expect(config.issues().isEmpty)
    }
    @Test func mapWidth() { expectOnly("map.width", .mustBePositive) { $0.map.width = 0 } }
    @Test func mapHeight() { expectOnly("map.height", .mustBePositive) { $0.map.height = -3 } }
    @Test func minDistance() { expectOnly("map.minDistanceFromPath", .mustNotBeNegative) { $0.map.minDistanceFromPath = -1 } }
    @Test func pathTooShort() { expectOnly("map.path", .pathTooShort) { $0.map.path = [Point(x: 0, y: 0)] } }
    @Test func missingTower() { expectOnly("towers.spore", .missingTower) { $0.towers[.spore] = nil } }
    @Test func towerCost() { expectOnly("towers.watch.cost", .mustBePositive) { $0.towers[.watch]?.cost = 0 } }
    @Test func towerRange() { expectOnly("towers.watch.range", .mustBePositive) { $0.towers[.watch]?.range = 0 } }
    @Test func towerDamage() { expectOnly("towers.watch.damage", .mustNotBeNegative) { $0.towers[.watch]?.damage = -1 } }
    @Test func towerInterval() { expectOnly("towers.spore.attackInterval", .mustBePositive) { $0.towers[.spore]?.attackInterval = 0 } }
    @Test func notANumberIsRejected() { expectOnly("towers.watch.range", .mustBePositive) { $0.towers[.watch]?.range = .nan } }
    @Test func chainValuesMissing() { expectOnly("towers.lightning", .missingChainValues) { $0.towers[.lightning]?.chainRadius = nil } }
    @Test func chainJumps() { expectOnly("towers.lightning.chainJumps", .mustNotBeNegative) { $0.towers[.lightning]?.chainJumps = -1 } }
    @Test func chainRadius() { expectOnly("towers.lightning.chainRadius", .mustBePositive) { $0.towers[.lightning]?.chainRadius = 0 } }
    @Test func chainFalloff() { expectOnly("towers.lightning.chainFalloff", .mustBeFraction) { $0.towers[.lightning]?.chainFalloff = 1.5 } }
    @Test func slowValuesMissing() { expectOnly("towers.spore", .missingSlowValues) { $0.towers[.spore]?.slowDuration = nil } }
    @Test func slowFactorZero() { expectOnly("towers.spore.slowFactor", .mustBeFraction) { $0.towers[.spore]?.slowFactor = 0 } }
    @Test func slowFactorOneIsAllowed() {
        var config = valid
        config.towers[.spore]?.slowFactor = 1
        #expect(config.issues().isEmpty)
    }
    @Test func slowDuration() { expectOnly("towers.spore.slowDuration", .mustBePositive) { $0.towers[.spore]?.slowDuration = 0 } }
    @Test func enemyHP() { expectOnly("enemies.raider.hp", .mustBePositive) { $0.enemies[.raider]?.hp = 0 } }
    @Test func enemySpeed() { expectOnly("enemies.runner.speed", .mustBePositive) { $0.enemies[.runner]?.speed = 0 } }
    @Test func enemyReward() { expectOnly("enemies.raider.reward", .mustNotBeNegative) { $0.enemies[.raider]?.reward = -5 } }
    @Test func enemyLeak() { expectOnly("enemies.brute.leakDamage", .mustBePositive) { $0.enemies[.brute]?.leakDamage = 0 } }
    @Test func noWaves() { expectOnly("waves", .noWaves) { $0.waves = [] } }
    @Test func emptyWave() { expectOnly("waves[2]", .emptyWave) { $0.waves[2].groups = [] } }
    @Test func hpScale() { expectOnly("waves[0].hpScale", .mustBePositive) { $0.waves[0].hpScale = 0 } }
    @Test func groupCount() { expectOnly("waves[3].groups[1].count", .mustBePositive) { $0.waves[3].groups[1].count = 0 } }
    @Test func groupInterval() { expectOnly("waves[0].groups[0].interval", .mustBePositive) { $0.waves[0].groups[0].interval = 0 } }
    @Test func groupDelay() { expectOnly("waves[3].groups[1].delay", .mustNotBeNegative) { $0.waves[3].groups[1].delay = -1 } }
    @Test func referencedEnemyMissing() {
        // Panzerbestie ist optional (MVP-Grenze): ohne Werte ist sie nur dort
        // ein Fehler, wo eine Welle sie ruft – Wellen 7, 9, 10.
        var config = valid
        config.enemies[.brute] = nil
        #expect(config.issues() == [
            ConfigIssue(field: "waves[6].groups[0].enemy", rule: .missingEnemy),
            ConfigIssue(field: "waves[8].groups[0].enemy", rule: .missingEnemy),
            ConfigIssue(field: "waves[9].groups[2].enemy", rule: .missingEnemy),
        ])
    }

    @Test("Mehrere Verstöße kommen alle auf einmal")
    func collectsAll() {
        var config = valid
        config.mission.fortressLives = 0
        config.towers[.watch]?.cost = 0
        #expect(config.issues().count == 2)
    }

    @Test("Meldung nennt den Ort in der Datei")
    func readableMessage() {
        let issue = ConfigIssue(field: "towers.watch.cost", rule: .mustBePositive)
        #expect(issue.description == "towers.watch.cost muss größer als 0 sein")
    }
}
