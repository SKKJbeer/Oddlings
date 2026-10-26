import OddlingsCore

/// Texte der Kampagnenkarte. Namen und Lehrsätze stehen in 05 (Region 1); wo 05
/// keinen Namen nennt, heißt die Mission nach ihrer Nummer, bis Steffen Namen
/// festlegt (07: Namen im Entwurf sind Platzhalter).
enum CampaignTexts {
    static let regionName = "Flüsterwald"
    static let regionLabel = "Region 1"
    static let start = "Starten"
    static let again = "Nochmal spielen"
    static let back = "Menü"
    static let raceLabel = "Volk"

    static func race(_ race: Race) -> String {
        switch race {
        case .dwarves: "Zwerge"
        case .elves: "Elfen"
        }
    }

    /// Eine Zeile, was das Volk tut (r-4-voelker.md, Bedienung). Ohne Zahlen:
    /// Die stehen in races.json und ändern sich mit dem Spieltest.
    static func raceDetail(_ race: Race?) -> String {
        switch race {
        case .dwarves: "Bollwerk: eine Mauer hält die Gegner auf. Wachtürme kosten weniger."
        case .elves: "Mondmal: Markierte nehmen mehr Schaden. Sporentürme reichen weiter."
        case nil: "Ohne Volk wirfst du den Steinregen."
        }
    }

    static func name(_ id: String) -> String {
        switch id {
        case "m1": "Mission 1"
        case "m2": "Mission 2"
        case "m3": "Mission 3"
        case "m4": "Mission 4"
        case "m5a": "Sumpfpfad"
        case "m6a": "Sumpfpfad II"
        case "m5b": "Ruinen"
        case "m6b": "Ruinen II"
        case "m7": "Mission 7"
        case "n1": "Nebenmission 1"
        case "n2": "Nebenmission 2"
        default: id
        }
    }

    /// Kurzer Name für Knoten und Sperrgründe.
    static func short(_ id: String) -> String {
        switch id {
        case "m5a", "m6a", "m5b", "m6b": name(id)
        case "n1": "N1"
        case "n2": "N2"
        default: id.dropFirst().description
        }
    }

    static func kind(_ kind: CampaignNodeKind) -> String {
        switch kind {
        case .main: "Hauptmission"
        case .side: "Nebenmission"
        case .boss: "Bossmission"
        }
    }

    /// Spalte „Lehrt" aus 05.
    static func lesson(_ id: String) -> String {
        switch id {
        case "m1": "Das Grundspiel: Türme gegen Plünderer und Flitzer."
        case "m2": "Ernten oder verteidigen."
        case "m3": "Vertiefen statt verbreitern."
        case "m4": "Aktiv eingreifen, zähe Ziele."
        case "m5a", "m6a": "Der Sumpf schickt Flitzer."
        case "m5b", "m6b": "Die Ruinen schicken Panzerbestien."
        case "m7": "Alles zusammen."
        default: "Eine Sonderregel für den zweiten Durchgang."
        }
    }

    static func novelty(_ novelty: CampaignNovelty?) -> String? {
        switch novelty {
        case .basics: "Wachturm, Blitzturm, Sporenturm"
        case .bank: "Neu: Zwergenbank"
        case .upgrades: "Neu: Aufwerten und Zielwahl"
        case .ability: "Neu: Festungsfähigkeit und Panzerbestie"
        case .specializations: "Neu: Spezialisierungen"
        case .boss: "Neu: der Boss des Flüsterwalds"
        case .specialRule: "Neu: Sonderregel"
        case nil: nil
        }
    }

    static func status(_ state: CampaignNodeState, totalStars: Int) -> String {
        switch state {
        case .completed: "Gewonnen"
        case .open: "Bereit"
        case .inPreparation: "In Arbeit: kommt mit einem der nächsten Bauten"
        case .locked(.after(let missing)): "Erst nach \(missing.map(name).joined(separator: " oder "))"
        case .locked(.stars(let needed)): "Ab \(needed) Sternen, du hast \(totalStars)"
        }
    }

    static func stars(_ count: Int, of total: Int) -> String { "\(count) von \(total) Sternen" }

    /// Für VoiceOver und die Oberflächentests: was der Knoten zeigt, in Worten.
    static func accessibilityValue(_ state: CampaignNodeState) -> String {
        switch state {
        case .completed(let stars): "gewonnen, \(stars) von \(StarRating.maximum) Sternen"
        case .open: "offen"
        case .inPreparation: "in Arbeit"
        case .locked: "gesperrt"
        }
    }
}
