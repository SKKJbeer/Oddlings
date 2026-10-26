import Foundation
import Testing
@testable import OddlingsCore

@Suite("Völker")
struct RaceTests {
    @Test("races.json lädt, hat jedes Volk und besteht die Prüfung")
    func bundled() throws {
        let table = try RaceTable.bundled()
        #expect(table[.dwarves]?.ability.kind == .bulwark)
        #expect(table[.elves]?.ability.kind == .moonMark)
        #expect(table.issues().isEmpty)
    }

    @Test("Ein Volk tauscht die Fähigkeit und skaliert nur die genannte Reichweite")
    func applying() throws {
        let base = TestConfig.make()
        let race = RaceConfig(ability: MoonMarkTests.ability, rangeFactor: [.spore: 1.5])
        let applied = base.applying(race)
        #expect(applied.ability == MoonMarkTests.ability)
        #expect(applied.towers[.spore]?.range == 4.5)
        var rest = applied
        rest.ability = base.ability
        rest.towers[.spore]?.range = base.towers[.spore]!.range
        #expect(rest == base, "sonst bleibt alles, wie es ist")
    }

    @Test("Mission 1 besteht die Prüfung für jedes Volk")
    func missionOnePerRace() throws {
        let mission = try BalanceConfig.missionOne()
        let table = try RaceTable.bundled()
        for race in Race.allCases {
            let config = try #require(table[race])
            #expect(mission.applying(config).issues().isEmpty, "\(race)")
        }
    }

    @Test("Prüfung: fehlendes Volk, ungültige Fähigkeit, Reichweite nicht positiv")
    func validation() {
        let table = RaceTable(races: [
            .dwarves: RaceConfig(ability: AbilityConfig(kind: .bulwark, cooldown: 10, snapDistance: 1),
                                 rangeFactor: [.watch: 0]),
        ])
        #expect(Set(table.issues()) == [
            ConfigIssue(field: "races.elves", rule: .missingRace),
            ConfigIssue(field: "races.dwarves.ability.duration", rule: .missingAbilityValue),
            ConfigIssue(field: "races.dwarves.rangeFactor.watch", rule: .mustBePositive),
        ])
    }

    @Test("Laden prüft: eine kaputte Datei kommt nicht durch")
    func loadValidates() {
        let data = Data(#"{ "races": { "dwarves": { "ability": { "kind": "bulwark", "cooldown": 10, "snapDistance": 1 } } } }"#.utf8)
        #expect(throws: ConfigError.self) { try RaceTable.load(from: data) }
        #expect(throws: ConfigError.self) { try RaceTable.load(from: Data("{".utf8)) }
    }

    @Test("Eine Fähigkeit ohne Art ist Steinregen, wie in Missionsdateien von 0.8.0")
    func missingKindIsStoneRain() throws {
        #expect(try BalanceConfig.missionOne().ability?.kind == .stoneRain)
    }
}
