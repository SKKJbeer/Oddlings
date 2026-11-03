import Foundation
import OddlingsCore
import OddlingsLab

// Balance-Labor auf der Kommandozeile (P2-6b). Liest nur Dateien aus dem Paket,
// schreibt nur ins Ausgabeverzeichnis; kein Netz. Unbekannte Argumente brechen ab,
// damit ein Tippfehler nicht still die ganze Matrix rechnet.

struct Options {
    var stage = "pr"
    var output = "build/balance"
    var nodes: [String]?
    var races: [Race]?
}

func parse(_ arguments: [String]) throws(LabError) -> Options {
    var options = Options()
    var rest = arguments[...]
    func value(_ flag: String) throws(LabError) -> String {
        guard let next = rest.popFirst(), !next.hasPrefix("--") else { throw .unknownArgument("\(flag) ohne Wert") }
        return next
    }
    while let flag = rest.popFirst() {
        switch flag {
        case "--stufe": options.stage = try value(flag)
        case "--ausgabe": options.output = try value(flag)
        case "--mission": options.nodes = (options.nodes ?? []) + [try value(flag)]
        case "--volk":
            let text = try value(flag)
            guard let race = Race(rawValue: text) else { throw .unknownArgument("Volk \(text)") }
            options.races = (options.races ?? []) + [race]
        default: throw .unknownArgument(flag)
        }
    }
    return options
}

do {
    let options = try parse(Array(CommandLine.arguments.dropFirst()))
    let result = try await Lab.run(stage: options.stage, nodes: options.nodes, races: options.races)
    let folder = URL(fileURLWithPath: options.output, isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let markdown = LabReport.markdown(result)
    try Data(markdown.utf8).write(to: folder.appendingPathComponent("bericht.md"))
    try Data(LabReport.csv(result).utf8).write(to: folder.appendingPathComponent("laeufe.csv"))
    print(markdown)
    exit(result.failed ? 1 : 0)
} catch {
    FileHandle.standardError.write(Data("oddlings-balance: \(error)\n".utf8))
    exit(2)
}
