import Foundation
import Testing
@testable import OddlingsCore

/// Avatarrang und Talente (R-6, r-6-avatarrang.md): Rang aus Sternen, Spielarten
/// als Konfiguration, Prüfung beim Laden.
@Suite("Avatarrang und Talente")
struct TalentTests {
    private let wide = TalentOption(id: "wide", scale: [.radius: 2, .damageFactor: 0.5])
    private let quick = TalentOption(id: "quick", scale: [.cooldown: 0.5])

    private func race(_ rows: [TalentRow]) -> RaceConfig {
        RaceConfig(ability: AbilityConfig(kind: .moonMark, cooldown: 30, snapDistance: 1, radius: 1, delay: 0.5,
                                          duration: 4, damageFactor: 1.6),
                   talents: rows)
    }

    private var rows: [TalentRow] {
        [TalentRow(id: "one", a: wide, b: TalentOption(id: "narrow", scale: [.radius: 0.5])),
         TalentRow(id: "two", a: quick, b: TalentOption(id: "slow", scale: [.cooldown: 2, .duration: 2]))]
    }

    @Test("Rang an den Schwellen")
    func rankFromStars() {
        #expect(AvatarRank.rank(stars: 0, thresholds: [3, 12]) == 1)
        #expect(AvatarRank.rank(stars: 2, thresholds: [3, 12]) == 1)
        #expect(AvatarRank.rank(stars: 3, thresholds: [3, 12]) == 2)
        #expect(AvatarRank.rank(stars: 11, thresholds: [3, 12]) == 2)
        #expect(AvatarRank.rank(stars: 12, thresholds: [3, 12]) == 3)
        #expect(AvatarRank.rank(stars: 40, thresholds: []) == 1)
        #expect(AvatarRank.unlockedRows(rank: 1) == 0)
        #expect(AvatarRank.unlockedRows(rank: 3) == 2)
    }

    @Test("Es gilt nur, was der Rang freigibt; freie Reihen ohne Wahl stehen auf A")
    func effectiveChoice() {
        #expect(AvatarRank.effective([.b, .b], unlockedRows: 0, rows: 2) == [])
        #expect(AvatarRank.effective([.b, .b], unlockedRows: 1, rows: 2) == [.b])
        #expect(AvatarRank.effective([], unlockedRows: 2, rows: 2) == [.a, .a])
        #expect(AvatarRank.effective([.b], unlockedRows: 5, rows: 2) == [.b, .a])
    }

    @Test("Spielarten ändern nur ihre Felder und verrechnen sich")
    func optionsScaleTheirFields() {
        let config = race(rows)
        let base = config.ability
        let both = config.with(talents: [.a, .b]).ability
        #expect(both.radius == 2)
        #expect(both.damageFactor == 0.8)
        #expect(both.cooldown == 60)
        #expect(both.duration == 8)
        #expect(both.delay == base.delay)
        #expect(both.snapDistance == base.snapDistance)
        #expect(config.with(talents: []).ability == base)
    }

    @Test("Jede spielbare Kombination: Grundform, dann alle Seiten der freien Reihen")
    func allChoices() {
        #expect(race(rows).allTalentChoices() == [[], [.a], [.b], [.a, .a], [.a, .b], [.b, .a], [.b, .b]])
    }

    @Test("Prüfung: Schwellen steigen, eine Reihe je Rang, nur vorhandene Felder, jede Kombination gültig")
    func validation() {
        var table = RaceTable(races: [.dwarves: race(rows), .elves: race(rows)], rankStars: [3, 12])
        // Die Testfähigkeit ist absichtlich ungültig (Faktor 0,8 bei A+B): Die
        // Kombination wird geprüft, nicht nur die Grundform.
        #expect(table.issues().contains { $0.field.hasPrefix("races.dwarves.talents[ab]") && $0.rule == .mustBeAboveOne })
        table.races[.dwarves]?.talents = [rows[0]]
        #expect(table.issues().contains { $0.field == "races.dwarves.talents" && $0.rule == .talentRowsDontMatchRanks })
        table.rankStars = [12, 3]
        #expect(table.issues().contains { $0.field == "rankStars" && $0.rule == .ranksOutOfOrder })
        let bulwark = RaceConfig(ability: AbilityConfig(kind: .bulwark, cooldown: 30, snapDistance: 1, duration: 4),
                                 talents: [TalentRow(id: "x", a: wide, b: quick)])
        let other = RaceTable(races: [.dwarves: bulwark, .elves: bulwark], rankStars: [3])
        #expect(other.issues().contains { $0.field == "races.dwarves.talents.0.a.radius" && $0.rule == .fieldNotInAbility })
    }

    @Test("Fünf Ränge, alle sechs Sterne einer, und je Rang eine Reihe (D-065)")
    func bundled() throws {
        let table = try RaceTable.bundled()
        #expect(table.rankStars == [6, 12, 18, 24])
        #expect(table.rank(stars: 5) == 1)
        #expect(table.rank(stars: 24) == 5)
        for race in Race.allCases {
            #expect(try #require(table[race]).talents?.count == 4, "\(race)")
            #expect(try #require(table[race]).allTalentChoices().count == 31, "\(race)")
        }
    }

    @Test("Talentwahl im Spielstand: gültige bleibt, kaputte kostet nur die Wahl")
    func savedTalents() throws {
        func avatar(_ talents: String) throws -> Avatar {
            let json = #"{"race":"elves","name":"Lyra","portrait":"elf-1""# + talents + "}"
            return try JSONDecoder().decode(Avatar.self, from: Data(json.utf8))
        }
        #expect(try avatar(#","talents":["b","a"]"#).talents == [.b, .a])
        #expect(try avatar("").talents == [])
        #expect(try avatar(#","talents":["b","c"]"#).talents == [])
        #expect(try avatar(#","talents":"b""#).talents == [])
        let long = "[" + Array(repeating: "\"a\"", count: Avatar.maxTalentRows + 1).joined(separator: ",") + "]"
        #expect(try avatar(#","talents":"# + long).talents == [])
        #expect(try avatar(#","talents":["b"]"#).name == "Lyra")
        var lyra = try #require(Avatar(race: .elves, name: "Lyra", portrait: "elf-1"))
        lyra.talents = [.b]
        let again = try JSONDecoder().decode(Avatar.self, from: try JSONEncoder().encode(lyra))
        #expect(again == lyra)
    }
}
