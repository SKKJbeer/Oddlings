import Foundation
import OddlingsCore

/// Bericht eines Laufs als Markdown für Menschen und CSV für Tabellen (K11).
public enum LabReport {
    public static func markdown(_ result: LabResult) -> String {
        var lines = ["# Balance-Labor, Stufe \(result.stage)", ""]
        let failures = result.findings.filter { $0.level == .failure }
        let warnings = result.findings.filter { $0.level == .warning }
        lines.append(failures.isEmpty
            ? "**Keine neue Verletzung.** \(result.findings.filter { $0.level == .known }.count) bekannte Befunde, \(warnings.count) Warnungen, \(result.records.count) Läufe."
            : "**\(failures.count) Zielwerte verletzt**, \(warnings.count) Warnungen, \(result.records.count) Läufe.")
        lines.append("")
        lines.append("## Zielwerte")
        lines.append("")
        lines.append("| Stand | Befund |")
        lines.append("|---|---|")
        let known = result.findings.filter { $0.level == .known }
        let ordered = failures + known + warnings + result.findings.filter { $0.level == .ok }
        for finding in ordered { lines.append("| \(finding.level.rawValue) | \(finding.text) |") }
        lines.append("")
        lines.append("## Siegquote je Bot und Mission")
        lines.append("")
        lines.append("| Mission | Volk | gierig | Menschenbot | Zufallsbot | Ø Leben Menschenbot |")
        lines.append("|---|---|---|---|---|---|")
        var keys: [(String, Race)] = []
        for record in result.records where !keys.contains(where: { $0.0 == record.node && $0.1 == record.race }) {
            keys.append((record.node, record.race))
        }
        for (node, race) in keys {
            let mine = result.records.filter { $0.node == node && $0.race == race }
            func rate(_ bot: LabRecord.Bot) -> String {
                let runs = mine.filter { $0.bot == bot }
                guard !runs.isEmpty else { return "–" }
                return "\(runs.filter(\.won).count)/\(runs.count)"
            }
            let humans = mine.filter { $0.bot == .human }
            let lives = humans.isEmpty ? "–" : Lab.format(Double(humans.map(\.livesLeft).reduce(0, +)) / Double(humans.count))
            lines.append("| \(node) | \(race.rawValue) | \(rate(.greedy)) | \(rate(.human)) | \(rate(.random)) | \(lives) |")
        }
        lines.append("")
        lines.append("## Reserve der Bauweisen (gieriger Bot, erstes Spielen)")
        lines.append("")
        lines.append("| Mission | Volk | Bauweise | Reserve |")
        lines.append("|---|---|---|---|")
        for record in result.records where record.bot == .greedy {
            lines.append("| \(record.node) | \(record.race.rawValue) | \(record.variant) | \(record.reserve.map(Lab.format) ?? "–") |")
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    public static func csv(_ result: LabResult) -> String {
        let kinds = TowerKind.allCases
        var lines = [(["mission", "volk", "bot", "variante", "sieg", "leben", "durchbrueche", "ticks", "gold", "reserve"]
            + kinds.map { "gebaut_\($0.rawValue)" } + ["verstoesse"]).joined(separator: ",")]
        for r in result.records {
            let fields = [r.node, r.race.rawValue, r.bot.rawValue, quoted(r.variant), r.won ? "1" : "0", "\(r.livesLeft)",
                          "\(r.leaks)", "\(r.ticks)", "\(r.goldLeft)", r.reserve.map(Lab.format) ?? ""]
                + kinds.map { "\(r.built[$0] ?? 0)" } + [quoted(r.violations.joined(separator: "; "))]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func quoted(_ text: String) -> String {
        text.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" })
            ? "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            : text
    }
}
