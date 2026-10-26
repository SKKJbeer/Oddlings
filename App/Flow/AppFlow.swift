import Foundation
import Observation
import OddlingsCore
import os

/// Schirmfolge und Fortschritt (Konzept r-spielrahmen.md). Rechnet selbst
/// nichts: Sterne kommen aus `StarRating`, offene Missionen aus der Region,
/// Lesen und Schreiben aus `SaveStore`.
@Observable
@MainActor
final class AppFlow {
    enum Screen: Equatable {
        case menu
        /// Avatar-Aufbau (R-5), einmal vor der ersten Karte.
        case setup
        case map
        case battle(node: String)
        case watch
        case spike
    }

    private(set) var screen: Screen
    let campaign: CampaignConfig
    private(set) var progress: CampaignProgress
    /// Gewählter Knoten auf der Karte; die Tafel zeigt ihn.
    var selectedNode: String
    /// Knoten, dessen Wertung gerade besser wurde. Die Karte hebt ihn hervor.
    private(set) var justImproved: String?
    /// Einmal aufgebaut, danach gesetzt (R-5, D-063).
    private(set) var avatar: Avatar?
    /// Das Volk des Avatars bestimmt jede Mission. Ohne Avatar (nur die
    /// Oberflächentests mit `--play`) gilt die Fähigkeit der Missionsdatei.
    var race: Race? { avatar?.race }
    /// Werte der Völker. Die Kerntests laden dieselbe Datei und fangen einen
    /// Fehler vor der Auslieferung; fehlt sie trotzdem, spielt die Mission ohne Volk.
    let races: RaceTable?

    @ObservationIgnored private let store: SaveStore?
    @ObservationIgnored private var save: SaveGame
    @ObservationIgnored private var writable: Bool
    private static let log = Logger(subsystem: "de.skkjbeer.oddlings", category: "save")

    /// `store` fehlt nur in Tests, die nichts schreiben wollen.
    init(campaign: CampaignConfig, store: SaveStore?, screen: Screen = .menu) {
        var loadedSave = SaveGame()
        var loadedWritable = false
        if let store {
            let loaded = store.load(campaign: campaign)
            for note in loaded.notes { Self.log.error("\(note, privacy: .public)") }
            loadedSave = loaded.save
            loadedWritable = loaded.writable
        }
        self.campaign = campaign
        self.store = store
        save = loadedSave
        writable = loadedWritable
        progress = loadedSave.progress
        avatar = loadedSave.avatar
        do {
            races = try RaceTable.bundled()
        } catch {
            races = nil
            Self.log.error("Völker nicht geladen: \(String(describing: error), privacy: .public)")
        }
        selectedNode = campaign.continueNode(progress: loadedSave.progress)?.id ?? campaign.nodes.first?.id ?? ""
        self.screen = screen
    }

    var continueNode: CampaignNode? { campaign.continueNode(progress: progress) }

    func state(of node: CampaignNode) -> CampaignNodeState { campaign.state(of: node, progress: progress) }

    // MARK: Schirme

    func showMenu() { screen = .menu }
    func showWatch() { screen = .watch }
    func showSpike() { screen = .spike }

    /// Ohne Avatar führt jeder Weg zur Karte erst durch den Aufbau.
    func showMap() {
        justImproved = nil
        screen = avatar == nil ? .setup : .map
    }

    /// Startet nur, was die Regeln öffnen. Die Karte zeigt gesperrte Knoten
    /// ohne Startknopf; dies ist die zweite Sicherung dahinter.
    func start(_ nodeID: String) {
        guard avatar != nil else { return showMap() }
        guard let node = campaign.node(nodeID), state(of: node).isPlayable else { return }
        selectedNode = nodeID
        justImproved = nil
        screen = .battle(node: nodeID)
    }

    func mission(for nodeID: String) -> BalanceConfig? {
        guard let name = campaign.node(nodeID)?.mission else { return nil }
        return try? BalanceConfig.bundledMission(named: name)
    }

    /// Die Mission, wie sie gespielt wird: mit dem Volk, falls eins gewählt ist.
    /// Die Simulation bekommt eine fertige Konfiguration und kennt keine Völker.
    func battleMission(for nodeID: String) -> BalanceConfig? {
        guard let mission = mission(for: nodeID) else { return nil }
        guard let race, let config = races?[race] else { return mission }
        return mission.applying(config)
    }

    // MARK: Avatar

    /// Legt den Avatar an, genau einmal: Danach ist das Volk gesetzt (D-063).
    /// Ein Wechsel kommt erst mit einer Spielwährung, über die Steffen noch
    /// entscheidet. Vom Aufbau aus geht es zur Karte.
    @discardableResult
    func createAvatar(race: Race, name: String, portrait: String) -> Bool {
        guard avatar == nil, let created = Avatar(race: race, name: name, portrait: portrait) else { return false }
        avatar = created
        save.avatar = created
        persist()
        if screen == .setup { screen = .map }
        return true
    }

    // MARK: Ergebnis

    /// Gespeichert wird hier, beim Ergebnis, nicht beim Verlassen der App: Beendet
    /// das System die App danach, ist der Sieg trotzdem da.
    @discardableResult
    func finish(_ nodeID: String, outcome: Outcome, livesLeft: Int) -> Int {
        let thresholds = mission(for: nodeID)?.mission.stars
        let stars = StarRating.stars(outcome: outcome, livesLeft: livesLeft, thresholds: thresholds)
        let next = progress.recording(stars: stars, for: nodeID)
        guard next != progress else { return stars }
        progress = next
        justImproved = nodeID
        save.progress = next
        persist()
        return stars
    }

    private func persist() {
        guard let store else { return }
        do {
            try store.save(save, allowed: writable)
        } catch {
            Self.log.error("Spielstand nicht geschrieben: \(String(describing: error), privacy: .public)")
        }
    }
}
