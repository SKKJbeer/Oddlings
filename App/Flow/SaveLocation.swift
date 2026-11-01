import Foundation
import OddlingsCore
import os

/// Wo der Spielstand liegt. Application Support, weil iOS dort nichts von sich
/// aus löscht und die Datei nicht in der Dateien-App erscheint.
enum SaveLocation {
    static func store() -> SaveStore {
        #if DEBUG
        if let name = argument(after: "--e2e-speicher") {
            // Eigenes Verzeichnis je Testlauf, damit ein Oberflächentest nie
            // den echten Stand berührt und die App für einen zweiten Start
            // wiederfindet, was der erste geschrieben hat.
            let safe = name.filter { $0.isLetter || $0.isNumber || $0 == "-" }
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("e2e-\(safe)")
            if ProcessInfo.processInfo.arguments.contains("--e2e-frisch") {
                wipeOnce(directory)
            }
            return SaveStore(directory: directory)
        }
        #endif
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return SaveStore(directory: base.appendingPathComponent("Oddlings", isDirectory: true))
    }

    #if DEBUG
    /// SwiftUI legt die Startansicht mehr als einmal an, und jede Anlage holt
    /// den Speicher. Gelöscht wird deshalb nur einmal je Prozess: Eine Marke mit
    /// der Prozessnummer im Verzeichnis sagt, dass dieser Start schon geleert
    /// hat. Sonst wäre ein eben gebauter Avatar beim nächsten Neustart weg.
    private static func wipeOnce(_ directory: URL) {
        let marker = directory.appendingPathComponent("e2e-prozess")
        let process = String(ProcessInfo.processInfo.processIdentifier)
        if (try? String(contentsOf: marker, encoding: .utf8)) == process { return }
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? process.write(to: marker, atomically: true, encoding: .utf8)
        Logger(subsystem: "de.skkjbeer.oddlings", category: "save")
            .notice("E2E-Speicher geleert: \(directory.lastPathComponent, privacy: .public)")
    }

    static func argument(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }
    #endif
}
