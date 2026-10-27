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
    /// Ein Sieg hat einen neuen Rang gebracht, und die Avatartafel war seitdem
    /// nicht offen. Das Schild weist darauf hin. Gilt nur bis zum Neustart.
    private(set) var newTalentWaiting = false
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
            Self.log.notice("Spielstand \(String(describing: loaded.source), privacy: .public), Avatar \(loaded.save.avatar == nil ? "fehlt" : "da", privacy: .public), \(store.directory.path, privacy: .public)")
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

    func showMenu() {
        showsAvatarPanel = false
        screen = .menu
    }
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
        showsAvatarPanel = false
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
        return mission.applying(config, talents: talents)
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

    // MARK: Rang und Talente (R-6, D-064)

    /// Aus den besten Sternen je Mission: sinkt nie und lässt sich nicht doppelt verdienen.
    var rank: Int { races?.rank(stars: progress.totalStars) ?? 1 }

    /// Sterne für den nächsten Rang, `nil` auf dem höchsten.
    var nextRankStars: Int? { races?.rankStars?.first { $0 > progress.totalStars } }

    var talentRows: [TalentRow] { race.flatMap { races?[$0]?.talents } ?? [] }

    var unlockedTalentRows: Int { min(AvatarRank.unlockedRows(rank: rank), talentRows.count) }

    /// Die Wahl, die in der Mission gilt.
    var talents: [TalentSide] {
        AvatarRank.effective(avatar?.talents ?? [], unlockedRows: unlockedTalentRows, rows: talentRows.count)
    }

    /// Umstellen kostet nichts (D-064) und gilt ab der nächsten Mission.
    /// Eine gesperrte Reihe lässt sich nicht wählen.
    @discardableResult
    func chooseTalent(row: Int, side: TalentSide) -> Bool {
        guard var changed = avatar, row >= 0, row < unlockedTalentRows else { return false }
        var sides = talents
        sides[row] = side
        changed.talents = sides
        avatar = changed
        save.avatar = changed
        persist()
        return true
    }

    /// Die Avatartafel liegt über Hauptmenü oder Karte; welcher Schirm darunter
    /// liegt, ändert sie nicht.
    private(set) var showsAvatarPanel = false

    func openAvatarPanel() {
        guard avatar != nil else { return }
        showsAvatarPanel = true
        newTalentWaiting = false
    }

    func closeAvatarPanel() { showsAvatarPanel = false }

    // MARK: Ergebnis

    /// Gespeichert wird hier, beim Ergebnis, nicht beim Verlassen der App: Beendet
    /// das System die App danach, ist der Sieg trotzdem da.
    @discardableResult
    func finish(_ nodeID: String, outcome: Outcome, livesLeft: Int) -> Int {
        let thresholds = mission(for: nodeID)?.mission.stars
        let stars = StarRating.stars(outcome: outcome, livesLeft: livesLeft, thresholds: thresholds)
        let next = progress.recording(stars: stars, for: nodeID)
        guard next != progress else { return stars }
        let before = rank
        progress = next
        if rank > before, unlockedTalentRows > 0 { newTalentWaiting = true }
        justImproved = nodeID
        save.progress = next
        persist()
        return stars
    }

    private func persist() {
        guard let store else { return }
        do {
            try store.save(save, allowed: writable)
            Self.log.notice("Spielstand geschrieben, Avatar \(self.save.avatar == nil ? "fehlt" : "da", privacy: .public)")
        } catch {
            Self.log.error("Spielstand nicht geschrieben: \(String(describing: error), privacy: .public)")
        }
    }
}
