import Foundation

/// Liest und schreibt den Spielstand in einem Verzeichnis, das die App vorgibt
/// (D-022). Liegt im Kern, weil er nur Foundation braucht und so unter Linux mit
/// echten Dateien getestet wird, auch mit beschädigten.
public struct SaveStore: Sendable {
    public enum Source: Equatable, Sendable {
        case primary
        /// Die Hauptdatei war unbrauchbar, die vorige Fassung gilt.
        case previous
        /// Es gab keinen brauchbaren Stand; das Spiel beginnt neu.
        case fresh
    }

    public struct Loaded: Equatable, Sendable {
        public var save: SaveGame
        public var source: Source
        /// Ist der vorhandene Stand von einer neueren App, darf diese ihn nicht
        /// überschreiben: Der Spieler bekäme ihn nach dem nächsten Update sonst
        /// nicht zurück.
        public var writable: Bool
        /// Gründe für das Protokoll: was nicht lesbar war und was verworfen wurde.
        public var notes: [String]
    }

    public enum WriteError: Error, Equatable {
        case readOnly
        case failed(String)
    }

    /// Ein Spielstand ist wenige hundert Byte groß. Was deutlich größer ist, ist
    /// keiner und wird gar nicht erst in den Speicher geladen.
    public static let maximumBytes = 64 * 1024

    public let directory: URL
    public var primaryURL: URL { directory.appendingPathComponent("save.json") }
    public var previousURL: URL { directory.appendingPathComponent("save.previous.json") }

    public init(directory: URL) {
        self.directory = directory
    }

    public func load(campaign: CampaignConfig) -> Loaded {
        var notes: [String] = []
        var writable = true
        for (url, source) in [(primaryURL, Source.primary), (previousURL, Source.previous)] {
            switch read(url, campaign: campaign) {
            case .missing:
                continue
            case .decoded(let decoded):
                notes += decoded.dropped.map { "\(url.lastPathComponent): verworfen \($0)" }
                return Loaded(save: decoded.save, source: source, writable: writable, notes: notes)
            case .failed(let reason):
                notes.append("\(url.lastPathComponent): \(reason)")
            case .newer(let version):
                notes.append("\(url.lastPathComponent): neueres Schema \(version), bleibt unberührt")
                writable = false
            }
        }
        return Loaded(save: SaveGame(), source: .fresh, writable: writable, notes: notes)
    }

    /// Erst die vorige Fassung sichern, dann atomar ersetzen: Bricht das
    /// Schreiben ab, liegt immer eine ganze Datei da, und ist die neue Datei
    /// beim nächsten Start doch kaputt, gilt die vorige.
    public func save(_ save: SaveGame, allowed: Bool = true) throws(WriteError) {
        guard allowed else { throw .readOnly }
        do {
            let data = try SaveGameCodec.encode(save)
            let files = FileManager.default
            try files.createDirectory(at: directory, withIntermediateDirectories: true)
            if files.fileExists(atPath: primaryURL.path) {
                if files.fileExists(atPath: previousURL.path) { try files.removeItem(at: previousURL) }
                try files.copyItem(at: primaryURL, to: previousURL)
            }
            try data.write(to: primaryURL, options: .atomic)
        } catch {
            throw .failed(String(describing: error))
        }
    }

    private enum ReadResult {
        case missing
        case decoded(SaveGameCodec.Decoded)
        case failed(String)
        case newer(Int)
    }

    private func read(_ url: URL, campaign: CampaignConfig) -> ReadResult {
        let files = FileManager.default
        guard files.fileExists(atPath: url.path) else { return .missing }
        if let size = (try? files.attributesOfItem(atPath: url.path))?[.size] as? NSNumber,
           size.intValue > Self.maximumBytes {
            return .failed("Datei zu groß (\(size.intValue) Byte)")
        }
        let data: Data
        do { data = try Data(contentsOf: url) } catch { return .failed(String(describing: error)) }
        do {
            return .decoded(try SaveGameCodec.decode(data, campaign: campaign))
        } catch .newerSchema(let version) {
            return .newer(version)
        } catch {
            return .failed(error.description)
        }
    }
}
