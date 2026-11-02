import Foundation
import Testing
@testable import OddlingsCore

/// Schmiede (R-7b, r-7b-schmiede.md): Erz aus Siegen und neuen Sternen, Stufen
/// nur für erhaltene Stücke, Prüfung von Tabelle und Spielstand.
@Suite("Schmiede")
struct ForgeTests {
    private let banner = EquipmentPiece(id: "watch-banner", slot: .banner, source: .init(mission: "a", stars: 1),
                                        bonus: [.towerRange: 1.1], tower: .watch,
                                        levels: [[.towerRange: 1.2], [.towerRange: 1.3]])
    private let amulet = EquipmentPiece(id: "quick", slot: .amulet, source: .init(mission: "a", stars: 3),
                                        bonus: [.abilityCooldown: 0.9], levels: [[.abilityCooldown: 0.8]])
    private let seal = EquipmentPiece(id: "purse", slot: .seal, source: .init(stars: 1), bonus: [.startGold: 1.1])
    private let forge = ForgeConfig(winOre: 3, newStarOre: 10, maxOre: 50, levelCosts: [20, 30])
    private var table: EquipmentTable { EquipmentTable(pieces: [banner, amulet, seal], forge: forge) }
    private let owned = CampaignProgress(records: [MissionRecord(mission: "a", bestStars: 1)])

    @Test("Erz: nichts bei Niederlage, sonst Sieg plus jeder neue Stern")
    func oreFromResults() {
        #expect(forge.ore(won: false, starsBefore: 0, starsAfter: 0) == 0)
        #expect(forge.ore(won: true, starsBefore: 0, starsAfter: 2) == 23)
        #expect(forge.ore(won: true, starsBefore: 2, starsAfter: 3) == 13)
        #expect(forge.ore(won: true, starsBefore: 3, starsAfter: 1) == 3, "Wiederholen bringt nur den Sieg")
    }

    @Test("Die Truhe hält höchstens maxOre; die Gutschrift meldet, was ankam")
    func creditIsCapped() {
        var state = ForgeState()
        #expect(table.credit(won: true, starsBefore: 0, starsAfter: 3, to: &state) == 33)
        #expect(table.credit(won: true, starsBefore: 0, starsAfter: 3, to: &state) == 17)
        #expect(state.ore == 50)
        #expect(EquipmentTable(pieces: [seal]).credit(won: true, starsBefore: 0, starsAfter: 3, to: &state) == 0,
                "ohne Schmiede kein Erz")
    }

    @Test("Schmieden zieht ab, hebt die Stufe und endet an der höchsten")
    func upgradeSteps() {
        var state = ForgeState(ore: 50)
        #expect(table.upgradeCost(of: "watch-banner", in: state) == 20)
        #expect(table.upgrade("watch-banner", in: &state, progress: owned))
        #expect(state.ore == 30 && table.level(of: "watch-banner", in: state) == 2)
        #expect(table.upgradeCost(of: "watch-banner", in: state) == 30)
        #expect(table.upgrade("watch-banner", in: &state, progress: owned))
        #expect(state.ore == 0 && table.level(of: "watch-banner", in: state) == 3)
        #expect(table.upgradeCost(of: "watch-banner", in: state) == nil)
        state = ForgeState(ore: 50)
        #expect(table.upgradeCost(of: "purse", in: state) == nil, "ein Stück ohne Stufen")
        #expect(!table.upgrade("purse", in: &state, progress: owned))
    }

    @Test("Nicht erhalten oder zu wenig Erz: nichts geschieht")
    func upgradeNeedsOwnershipAndOre() {
        var poor = ForgeState(ore: 19)
        #expect(!table.upgrade("watch-banner", in: &poor, progress: owned))
        #expect(poor == ForgeState(ore: 19))
        var rich = ForgeState(ore: 50)
        #expect(!table.upgrade("quick", in: &rich, progress: owned), "Amulett braucht drei Sterne")
        #expect(rich == ForgeState(ore: 50))
    }

    @Test("Die Mission trägt die geschmiedete Stufe, nicht erhaltene Stücke keine")
    func effectiveUsesLevels() {
        let state = ForgeState(levels: [EquipmentLevel(piece: "watch-banner", level: 3),
                                        EquipmentLevel(piece: "quick", level: 2)])
        let loadout = EquipmentLoadout(banner: "watch-banner", amulet: "quick")
        #expect(table.effective(loadout, progress: owned, forge: state).map(\.bonus) == [[.towerRange: 1.3]])
        let all = CampaignProgress(records: [MissionRecord(mission: "a", bestStars: 3)])
        #expect(table.effective(loadout, progress: all, forge: state).map(\.bonus)
                == [[.towerRange: 1.3], [.abilityCooldown: 0.8]])
        let tooHigh = ForgeState(levels: [EquipmentLevel(piece: "quick", level: 7)])
        #expect(table.level(of: "quick", in: tooHigh) == 2, "über dem Stück zählt die höchste Stufe")
        #expect(EquipmentTable(pieces: [banner]).level(of: "watch-banner", in: state) == 1, "ohne Schmiede Stufe I")
    }

    @Test("Höchste Stufe in den Belegungen der Balancetests")
    func fullLoadoutsAtMaxLevel() {
        #expect(table.fullLoadouts(atMaxLevel: true).map { $0.map(\.bonus) }
                == [[[.towerRange: 1.3], [.abilityCooldown: 0.8], [.startGold: 1.1]]])
    }

    @Test("Die Prüfung findet schwächere Stufen, fremde Felder, fehlende Preise und kaputte Schmiedewerte")
    func validation() {
        let weaker = EquipmentPiece(id: "a", slot: .banner, source: .init(stars: 1), bonus: [.towerCost: 0.9],
                                    levels: [[.towerCost: 0.95]])
        let other = EquipmentPiece(id: "b", slot: .amulet, source: .init(stars: 1), bonus: [.abilityCooldown: 0.9],
                                   levels: [[.abilityCooldown: 0.8, .startGold: 1.1]])
        let long = EquipmentPiece(id: "c", slot: .seal, source: .init(stars: 1), bonus: [.startGold: 1.1],
                                  levels: [[.startGold: 1.2], [.startGold: 1.3], [.startGold: 1.4]])
        let broken = ForgeConfig(winOre: -1, newStarOre: 0, maxOre: 0, levelCosts: [20, 0])
        let issues = EquipmentTable(pieces: [weaker, other, long], forge: broken).issues()
        let found = Set(issues.map { "\($0.field) \($0.rule)" })
        #expect(found == ["pieces.0.levels.0.towerCost levelNotStronger",
                          "pieces.1.levels.0.startGold levelFieldsDiffer",
                          "pieces.2.levels levelWithoutCost",
                          "forge.winOre mustNotBeNegative", "forge.newStarOre mustBePositive",
                          "forge.maxOre mustBePositive", "forge.levelCosts.1 mustBePositive"])
        #expect(table.issues().isEmpty)
    }

    @Test("Die mitgelieferte Tabelle hat eine Schmiede und zwei Stufen je Stück")
    func bundledForge() throws {
        let bundled = try EquipmentTable.bundled(campaign: try CampaignConfig.regionOne())
        let forge = try #require(bundled.forge)
        #expect(forge.newStarOre > forge.winOre, "neue Sterne geben mehr als Wiederholen")
        #expect(bundled.pieces.allSatisfy { $0.maxLevel == forge.levelCosts.count + 1 })
    }

    @Test("Spielstand: Erz und Stufen überstehen die Datei, Kaputtes kostet nur sich selbst")
    func savedStateIsCheckedOnLoad() throws {
        let state = ForgeState(ore: 42, levels: [EquipmentLevel(piece: "quick", level: 2),
                                                 EquipmentLevel(piece: "watch-banner", level: 3)])
        let data = try JSONEncoder().encode(state)
        #expect(try JSONDecoder().decode(ForgeState.self, from: data) == state)
        func decode(_ json: String) throws -> ForgeState {
            try JSONDecoder().decode(ForgeState.self, from: Data(json.utf8))
        }
        #expect(try decode(#"{"ore":-5,"levels":[{"piece":"quick","level":2}]}"#)
                == ForgeState(levels: [EquipmentLevel(piece: "quick", level: 2)]))
        #expect(try decode(#"{"ore":100000}"#).ore == 0, "über der Formgrenze")
        #expect(try decode(#"{"ore":"viel"}"#).ore == 0)
        #expect(try decode(#"{"ore":7,"levels":[{"piece":"Quick!","level":2},{"piece":"quick","level":1},"#
                           + #"{"piece":"seal","level":12},{"piece":"purse","level":2},{"piece":"purse","level":3},{"level":2}]}"#)
                == ForgeState(ore: 7, levels: [EquipmentLevel(piece: "purse", level: 2)]))
        #expect(try decode(#"{"ore":7,"levels":"alle"}"#) == ForgeState(ore: 7))
    }
}
