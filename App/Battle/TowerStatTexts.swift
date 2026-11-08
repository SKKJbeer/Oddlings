import Foundation
import OddlingsCore

/// Texte der Wertetafel am Turm (D-130). Zahlen immer deutsch geschrieben und
/// unabhängig von der Spracheinstellung des Geräts, damit Tests und
/// Bildschirmfotos dieselben Zeichen sehen.
enum TowerStatTexts {
    static func label(_ figure: TowerFigure, kind: TowerKind) -> String {
        switch figure {
        case .damagePerSecond: kind == .lightning ? "Schaden/s, Kette" : "Schaden/s"
        case .damage: kind == .lightning ? "Erster Treffer" : "Schaden"
        case .rate: kind == .spore ? "Puls" : "Tempo"
        case .range: "Reichweite"
        case .targets: "Ziele/Schuss"
        case .chainTargets: "Kette"
        case .slow: "Bremst um"
        case .slowDuration: "Dauer"
        case .vulnerable: "Verwundbar"
        }
    }

    /// Wert mit Einheit, wie er in der Kachel steht.
    static func value(_ figure: TowerFigure, _ value: Double) -> String {
        switch figure {
        case .damagePerSecond: value >= 100 ? whole(value) : decimal(value, 1)
        case .damage: value.rounded() == value ? whole(value) : decimal(value, 1)
        case .rate: "\(decimal(value, 2))/s"
        case .range: decimal(value, 1)
        case .targets, .chainTargets: whole(value)
        case .slow: "\(whole(value * 100)) %"
        case .slowDuration: "\(decimal(value, 1)) s"
        case .vulnerable: "+\(whole(value * 100)) %"
        }
    }

    /// Kurze Einheit hinter dem Wert, wo die Zahl allein nicht trägt.
    static func unit(_ figure: TowerFigure) -> String? {
        switch figure {
        case .range: "Felder"
        case .targets, .chainTargets: "Ziele"
        default: nil
        }
    }

    /// Das Schild neben dem neuen Wert: „+50 %“, „+6“, „gleich“ oder nil,
    /// wenn es keinen alten Wert gibt. Prozent, wo das Verhältnis zählt;
    /// Stückzahl bei Zielen; Prozentpunkte bei Anteilen; Schaden als Betrag,
    /// weil man ihn gegen das Leben der Gegner hält.
    static func delta(_ change: TowerChange) -> String? {
        if change.isUnchanged { return same }
        guard let difference = change.difference else { return nil }
        switch change.figure {
        case .damage, .targets, .chainTargets:
            return signed(change.figure == .damage ? number(difference) : whole(difference))
        case .slow, .vulnerable:
            return signed(whole(difference * 100))
        case .damagePerSecond, .rate, .range, .slowDuration:
            guard let ratio = change.ratio else { return signed(number(difference)) }
            return "\(signed(whole(ratio * 100))) %"
        }
    }

    static let same = "gleich"

    /// Für VoiceOver: „Schaden: 12 auf 18, +6“.
    static func spoken(_ change: TowerChange, kind: TowerKind, comparing: Bool) -> String {
        let name = label(change.figure, kind: kind)
        guard let after = change.after else { return name }
        let now = value(change.figure, after)
        guard comparing, let before = change.before, !change.isUnchanged else { return "\(name): \(now)" }
        return "\(name): \(value(change.figure, before)) auf \(now), \(delta(change) ?? "")"
    }

    /// Kampfbilanz eines Kampfturms (D-130), eine Zeile.
    static func tally(_ tower: Tower, seconds: Int) -> String {
        let since = "seit \(BattleTexts.clock(seconds))"
        if tower.kind == .spore {
            return "\(grouped(tower.slowHits)) gebremst · \(grouped(tower.kills)) erledigt · \(since)"
        }
        return "\(grouped(Int(tower.damageDealt.rounded(.down)))) Schaden · \(grouped(tower.kills)) erledigt · \(since)"
    }

    static let newTargetMode = "Neu: Zielwahl (Erster, Letzter, Stärkster)"

    // MARK: Zahlen

    static func whole(_ value: Double) -> String { grouped(Int(value.rounded())) }

    static func decimal(_ value: Double, _ places: Int) -> String {
        String(format: "%.\(places)f", locale: Locale(identifier: "en_US_POSIX"), value)
            .replacingOccurrences(of: ".", with: ",")
    }

    private static func number(_ value: Double) -> String {
        value.rounded() == value ? whole(value) : decimal(value, 1)
    }

    private static func signed(_ text: String) -> String {
        text.hasPrefix("-") ? "−" + text.dropFirst() : "+" + text
    }

    /// Tausenderpunkt wie im Deutschen: 1.240.
    static func grouped(_ value: Int) -> String {
        let digits = String(abs(value))
        var out = ""
        for (index, digit) in digits.enumerated() {
            if index > 0, (digits.count - index) % 3 == 0 { out.append(".") }
            out.append(digit)
        }
        return value < 0 ? "-" + out : out
    }
}
