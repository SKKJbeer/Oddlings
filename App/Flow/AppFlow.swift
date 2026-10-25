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
        selectedNode = campaign.continueNode(progress: loadedSave.progress)?.id ?? campaign.nodes.first?.id ?? ""
        self.screen = screen
    }

    var continueNode: CampaignNode? { campaign.continueNode(progress: progress) }

    func state(of node: CampaignNode) -> CampaignNodeState { campaign.state(of: node, progress: progress) }

    // MARK: Schirme

    func showMenu() { screen = .menu }
    func showWatch() { screen = .watch }
    func showSpike() { screen = .spike }

    func showMap() {
        justImproved = nil
        screen = .map
    }

    /// Startet nur, was die Regeln öffnen. Die Karte zeigt gesperrte Knoten
    /// ohne Startknopf; dies ist die zweite Sicherung dahinter.
    func start(_ nodeID: String) {
        guard let node = campaign.node(nodeID), state(of: node).isPlayable else { return }
        selectedNode = nodeID
        justImproved = nil
        screen = .battle(node: nodeID)
    }

    func mission(for nodeID: String) -> BalanceConfig? {
        guard let name = campaign.node(nodeID)?.mission else { return nil }
        return try? BalanceConfig.bundledMission(named: name)
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
