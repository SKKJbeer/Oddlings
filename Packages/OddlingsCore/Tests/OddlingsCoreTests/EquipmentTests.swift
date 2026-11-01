import Foundation
import Testing
@testable import OddlingsCore

/// Ausrüstung des Avatars (R-7a, r-7-ausruestung.md): Besitz aus dem
/// Fortschritt, Boni nur auf ihre Felder, Prüfung beim Laden.
@Suite("Ausrüstung")
struct EquipmentTests {
    private let banner = EquipmentPiece(id: "watch-banner", slot: .banner, source: .init(mission: "a", stars: 1),
                                        bonus: [.towerRange: 1.5], tower: .watch)
    private let amulet = EquipmentPiece(id: "quick", slot: .amulet, source: .init(mission: "a", stars: 3),
                                        bonus: [.abilityCooldown: 0.5])
    private let seal = EquipmentPiece(id: "purse", slot: .seal, source: .init(stars: 4),
                                      bonus: [.startGold: 1.25, .fortressLives: 1.5])
    private var table: EquipmentTable { EquipmentTable(pieces: [banner, amulet, seal]) }

    private func progress(_ stars: [String: Int]) -> CampaignProgress {
        CampaignProgress(records: stars.keys.sorted().map { MissionRecord(mission: $0, bestStars: stars[$0]!) })
    }

    @Test("Besitz folgt aus den besten Sternen: je Mission oder als Summe")
    func ownershipFromProgress() {
        #expect(!table.owns("watch-banner", progress: progress([:])))
        #expect(table.owns("watch-banner", progress: progress(["a": 1])))
        #expect(!table.owns("quick", progress: progress(["a": 2, "b": 3])))
        #expect(table.owns("quick", progress: progress(["a": 3])))
        #expect(!table.owns("purse", progress: progress(["a": 3])))
        #expect(table.owns("purse", progress: progress(["a": 2, "b": 2])))
        #expect(!table.owns("unknown", progress: progress(["a": 3])))
    }

    @Test("Es gilt nur, was es gibt, auf seinen Platz gehört und schon erhalten ist")
    func effectiveLoadout() {
        let all = EquipmentLoadout(banner: "watch-banner", amulet: "quick", seal: "purse")
        #expect(table.effective(all, progress: progress(["a": 3, "b": 1])).map(\.id) == ["watch-banner", "quick", "purse"])
        #expect(table.effective(all, progress: progress(["a": 1])).map(\.id) == ["watch-banner"])
        let wrong = EquipmentLoadout(banner: "quick", amulet: "gone", seal: nil)
        #expect(table.effective(wrong, progress: progress(["a": 3])).isEmpty)
    }

    @Test("Boni ändern nur ihre Felder; Gold und Leben bleiben ganze Werte")
    func bonusesScaleTheirFields() throws {
        let base = try BalanceConfig.missionOne()
        let geared = base.applying(equipment: [banner, amulet, seal])
        let watch = try #require(base.towers[.watch]), lightning = try #require(base.towers[.lightning])
        #expect(geared.towers[.watch]?.range == watch.range * 1.5)
        #expect(geared.towers[.watch]?.damage == watch.damage)
        #expect(geared.towers[.lightning] == lightning, "Banner nur für Wachtürme")
        #expect(geared.mission.startGold == Int((Double(base.mission.startGold) * 1.25).rounded()))
        #expect(geared.mission.fortressLives == Int((Double(base.mission.fortressLives) * 1.5).rounded()))
        #expect(geared.ability?.cooldown == base.ability.map { $0.cooldown * 0.5 })
        #expect(geared.waves == base.waves)
        #expect(geared.enemies == base.enemies)
        #expect(base.applying(equipment: []) == base)
    }

    @Test("Ein Banner ohne Turmart wirkt auf jeden Turm")
    func bannerForAllTowers() throws {
        let base = try BalanceConfig.missionOne()
        let storm = EquipmentPiece(id: "storm", slot: .banner, source: .init(stars: 1), bonus: [.towerDamage: 2])
        let geared = base.applying(equipment: [storm])
        for kind in TowerKind.allCases {
            #expect(geared.towers[kind]?.damage == base.towers[kind].map { $0.damage * 2 }, "\(kind)")
        }
    }

    @Test("Jede volle Belegung: ein Stück je Platz")
    func fullLoadouts() {
        let second = EquipmentPiece(id: "storm", slot: .banner, source: .init(stars: 1), bonus: [.towerDamage: 2])
        let loadouts = EquipmentTable(pieces: [banner, second, amulet, seal]).fullLoadouts()
        #expect(loadouts.map { $0.map(\.id) } == [["watch-banner", "quick", "purse"], ["storm", "quick", "purse"]])
    }

    @Test("Die Prüfung findet kaputte Tabellen")
    func issues() throws {
        let campaign = CampaignConfig(id: "r", nodes: [
            CampaignNode(id: "a", kind: .main, position: Point(x: 0, y: 0)),
            CampaignNode(id: "b", kind: .main, position: Point(x: 1, y: 0)),
        ])
        #expect(table.issues(campaign: campaign).isEmpty)
        var broken = table
        broken.pieces[0].id = "Watch Banner"
        broken.pieces[1].source = .init(mission: "zz", stars: 4)
        broken.pieces[2].bonus = [.towerDamage: 1.1, .startGold: 0]
        broken.pieces.append(EquipmentPiece(id: "quick", slot: .amulet, source: .init(stars: 7), bonus: [:]))
        let rules = broken.issues(campaign: campaign).map(\.rule)
        #expect(rules.contains(.invalidID))
        #expect(rules.contains(.unknownMission))
        #expect(rules.filter { $0 == .starsAboveMaximum }.count == 2, "4 Sterne in einer Mission, 7 in einer Region mit 6")
        #expect(rules.contains(.fieldNotInSlot))
        #expect(rules.contains(.mustBePositive))
        #expect(rules.contains(.duplicateID))
        #expect(rules.contains(.noBonus))
        #expect(EquipmentTable(pieces: [banner]).issues().map(\.rule) == [.emptySlot, .emptySlot])
    }

    @Test("Die mitgelieferte Tabelle besteht die Prüfung gegen Region 1")
    func bundledTable() throws {
        let table = try EquipmentTable.bundled(campaign: try CampaignConfig.regionOne())
        for slot in EquipmentSlot.allCases { #expect(!table.pieces(in: slot).isEmpty, "\(slot)") }
    }

    /// Ein Amulett kürzt die Abklingzeit; jede Fähigkeit muss danach noch ihre
    /// eigenen Regeln einhalten (Dauer nicht länger als die Abklingzeit).
    @Test("Jede Volksfähigkeit bleibt mit jedem Amulett und jeder Talentwahl gültig")
    func amuletsKeepAbilitiesValid() throws {
        let races = try RaceTable.bundled()
        let table = try EquipmentTable.bundled()
        let base = try BalanceConfig.missionOne()
        for race in Race.allCases {
            let config = try #require(races[race])
            for choice in config.allTalentChoices() {
                for amulet in table.pieces(in: .amulet) {
                    let ability = try #require(base.applying(config, talents: choice, equipment: [amulet]).ability)
                    #expect(ability.issues(field: "\(race)").isEmpty, "\(race) \(choice) \(amulet.id)")
                }
            }
        }
    }

    @Test("Laden behält gültige Kennungen und verwirft kaputte einzeln")
    func loadoutDecoding() throws {
        let json = #"{"banner":"watch-banner","amulet":"Böse Kennung","seal":7}"#
        let loadout = try JSONDecoder().decode(EquipmentLoadout.self, from: Data(json.utf8))
        #expect(loadout == EquipmentLoadout(banner: "watch-banner"))
        let roundTrip = try JSONDecoder().decode(EquipmentLoadout.self, from: JSONEncoder().encode(loadout))
        #expect(roundTrip == loadout)
    }
}
