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
        /// Avatar-Menü (R-6): eigener Schirm, damit es mit weiteren
        /// Abschnitten wachsen kann, ohne eine Tafel zu überfüllen.
        case avatar
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
    /// Ein Sieg hat einen neuen Rang gebracht, und das Avatar-Menü war seitdem
    /// nicht offen. Das Schild weist darauf hin. Gilt nur bis zum Neustart.
    private(set) var newTalentWaiting = false
    /// Werte der Völker. Die Kerntests laden dieselbe Datei und fangen einen
    /// Fehler vor der Auslieferung; fehlt sie trotzdem, spielt die Mission ohne Volk.
    let races: RaceTable?
    /// Ausrüstung (R-7a). Fehlt die Datei, spielt jede Mission ohne Ausrüstung.
    let equipment: EquipmentTable?
    /// Ein Sieg hat ein Stück gebracht, und das Avatar-Menü war seitdem nicht offen.
    private(set) var newEquipmentWaiting = false
    /// Welcher Abschnitt des Avatar-Menüs beim Öffnen vorn liegt.
    private(set) var avatarSection: AvatarSection = .talents

    enum AvatarSection: Equatable { case talents, equipment, forge }

    /// Wie die Schlacht beginnt, die beim Start der App aus dem Spielstand kommt
    /// (P2-2, D-074). `state` fehlt, wenn die Mission neu beginnen muss.
    struct ResumePlan: Equatable {
        let node: String
        let seed: UInt64
        let state: GameState?
        let notice: String
    }

    /// Gilt, bis die Schlacht endet, verlassen oder neu gestartet wird.
    private(set) var resume: ResumePlan?

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
        do {
            equipment = try EquipmentTable.bundled(campaign: campaign)
        } catch {
            equipment = nil
            Self.log.error("Ausrüstung nicht geladen: \(String(describing: error), privacy: .public)")
        }
        selectedNode = campaign.continueNode(progress: loadedSave.progress)?.id ?? campaign.nodes.first?.id ?? ""
        self.screen = screen
        restoreBattle()
    }

    // MARK: Fortsetzen (P2-2)

    /// Lief beim letzten Beenden eine Mission, öffnet die App direkt in ihr,
    /// angehalten (Karte S12, Empfehlung). Passt der Stand nicht mehr zu den
    /// Regeln (Update) oder besteht er die Prüfung nicht, beginnt die Mission neu
    /// mit Hinweis (D-022). Nur beim normalen Start ins Hauptmenü: Die
    /// Oberflächentests mit `--play` und die Vorführung wählen ihren Schirm selbst.
    private func restoreBattle() {
        guard let battle = save.battle, screen == .menu else { return }
        guard avatar != nil, let node = campaign.node(battle.node), state(of: node).isPlayable,
              let mission = battleMission(for: node.id) else {
            Self.log.error("Gesicherte Mission \(battle.node, privacy: .public) nicht spielbar, verworfen")
            return discardSavedBattle()
        }
        let sameRules = mission.fingerprint == battle.rules
        let problems = sameRules ? battle.problems(for: Simulation(config: mission)) : []
        let notice: String
        var state: GameState?
        if !sameRules {
            Self.log.notice("Gesicherte Mission unter alten Regeln, beginnt neu")
            notice = BattleTexts.restartedAfterUpdate
        } else if !problems.isEmpty {
            Self.log.error("Gesicherte Mission ungültig: \(problems.joined(separator: "; "), privacy: .public)")
            notice = BattleTexts.restartedAfterDamage
        } else {
            state = battle.state
            notice = BattleTexts.resumed
        }
        resume = ResumePlan(node: node.id, seed: battle.seed, state: state, notice: notice)
        if state == nil { discardSavedBattle() }
        selectedNode = node.id
        screen = .battle(node: node.id)
    }

    /// Sichert die laufende Mission, wenn die App in den Hintergrund geht. Der
    /// Fingerabdruck kommt aus der Konfiguration, die `battleMission` jetzt
    /// liefert, nicht aus der Schlacht: Die trägt in Testläufen geänderte Zeiten.
    func suspend(_ nodeID: String, seed: UInt64, state: GameState) {
        guard store != nil, !state.isOver, let mission = battleMission(for: nodeID) else { return }
        save.battle = SuspendedBattle(node: nodeID, rules: mission.fingerprint, seed: seed, state: state)
        persist()
    }

    /// „Zurück“ aus der Schlacht beendet die Mission; gesichert bleibt nichts.
    func leaveBattle() {
        resume = nil
        discardSavedBattle()
        showMap()
    }

    private func discardSavedBattle() {
        guard save.battle != nil else { return }
        save.battle = nil
        persist()
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
        resume = nil
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
        return mission.applying(config, talents: talents, equipment: equippedPieces)
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

    /// Sterne, ab denen der jetzige Rang gilt; für den Fortschrittsbalken.
    var rankFloorStars: Int { races?.rankStars?.last { $0 <= progress.totalStars } ?? 0 }

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

    // MARK: Ausrüstung (R-7a, D-066, D-070)

    /// Was in der Mission gilt: nur Stücke, die es gibt und die erhalten sind.
    var equippedPieces: [EquipmentPiece] {
        guard let avatar, let equipment else { return [] }
        return equipment.effective(avatar.equipment, progress: progress, forge: avatar.forge)
    }

    /// Hinweis am Avatarschild; das neue Talent geht vor.
    var avatarNews: String? {
        newTalentWaiting ? AvatarTexts.newTalent : newEquipmentWaiting ? AvatarTexts.newEquipment : nil
    }

    func owns(_ id: String) -> Bool { equipment?.owns(id, progress: progress) ?? false }

    func isEquipped(_ id: String) -> Bool { equippedPieces.contains { $0.id == id } }

    private var ownedIDs: [String] { equipment?.pieces.map(\.id).filter(owns) ?? [] }

    /// Anlegen kostet nichts und gilt ab der nächsten Mission. `nil` legt ab.
    /// Ein Stück, das noch nicht erhalten ist, lässt sich nicht anlegen.
    @discardableResult
    func equip(_ id: String?, in slot: EquipmentSlot) -> Bool {
        guard var changed = avatar else { return false }
        if let id {
            guard let piece = equipment?.piece(id), piece.slot == slot, owns(id) else { return false }
        }
        changed.equipment[slot] = id
        avatar = changed
        save.avatar = changed
        persist()
        return true
    }

    /// Neu erhaltene Stücke wandern auf einen freien Platz, damit eine
    /// Belohnung sofort wirkt; ein belegter Platz bleibt, wie er ist.
    private func receive(_ ids: [String]) {
        guard !ids.isEmpty, var changed = avatar, let equipment else { return }
        newEquipmentWaiting = true
        for id in ids {
            guard let piece = equipment.piece(id), changed.equipment[piece.slot] == nil else { continue }
            changed.equipment[piece.slot] = id
        }
        avatar = changed
        save.avatar = changed
    }

    // MARK: Schmiede (R-7b, D-070)

    var ore: Int { avatar?.forge.ore ?? 0 }

    /// Ohne Schmiedewerte gibt es den Reiter nicht.
    var hasForge: Bool { equipment?.forge != nil }

    func level(of id: String) -> Int {
        guard let avatar, let equipment else { return 1 }
        return equipment.level(of: id, in: avatar.forge)
    }

    func upgradeCost(of id: String) -> Int? {
        guard let avatar, let equipment else { return nil }
        return equipment.upgradeCost(of: id, in: avatar.forge)
    }

    /// Eine Stufe schmieden; gilt ab der nächsten Mission wie das Anlegen.
    @discardableResult
    func forge(_ id: String) -> Bool {
        guard var changed = avatar, let equipment,
              equipment.upgrade(id, in: &changed.forge, progress: progress) else { return false }
        avatar = changed
        save.avatar = changed
        persist()
        return true
    }

    /// Wohin „Zurück“ im Avatar-Menü führt: dorthin, wo es geöffnet wurde.
    private(set) var avatarReturn: Screen = .menu

    /// Öffnet das Avatar-Menü aus Hauptmenü oder Karte.
    func openAvatar() {
        guard avatar != nil, screen == .menu || screen == .map else { return }
        avatarReturn = screen
        avatarSection = newEquipmentWaiting && !newTalentWaiting ? .equipment : .talents
        newTalentWaiting = false
        newEquipmentWaiting = false
        screen = .avatar
    }

    func closeAvatar() {
        guard screen == .avatar else { return }
        screen = avatarReturn
    }

    // MARK: Ergebnis

    /// Erz aus dem letzten Ergebnis, für die Ergebnistafel.
    private(set) var lastOre = 0

    /// Zeile der Ergebnistafel, `nil` ohne Erz.
    var lastReward: String? { lastOre > 0 ? AvatarTexts.oreGain(lastOre) : nil }

    /// Gespeichert wird hier, beim Ergebnis, nicht beim Verlassen der App: Beendet
    /// das System die App danach, ist der Sieg trotzdem da.
    @discardableResult
    func finish(_ nodeID: String, outcome: Outcome, livesLeft: Int) -> Int {
        let thresholds = mission(for: nodeID)?.mission.stars
        let stars = StarRating.stars(outcome: outcome, livesLeft: livesLeft, thresholds: thresholds)
        let next = progress.recording(stars: stars, for: nodeID)
        // Die Mission ist entschieden; fortgesetzt wird sie nicht mehr.
        let hadBattle = save.battle != nil
        save.battle = nil
        resume = nil
        // Erz gibt auch der wiederholte Sieg, deshalb vor dem Vergleich der Sterne.
        lastOre = 0
        if var changed = avatar, let equipment {
            lastOre = equipment.credit(won: outcome == .won, starsBefore: progress.stars(for: nodeID),
                                       starsAfter: stars, to: &changed.forge)
            if lastOre > 0 {
                avatar = changed
                save.avatar = changed
            }
        }
        guard next != progress else {
            if lastOre > 0 || hadBattle { persist() }
            return stars
        }
        let before = rank, ownedBefore = ownedIDs
        progress = next
        if rank > before, unlockedTalentRows > 0 { newTalentWaiting = true }
        receive(ownedIDs.filter { !ownedBefore.contains($0) })
        justImproved = nodeID
        save.progress = next
        persist()
        return stars
    }

    /// Zeigt diese Mission die stillen Zeichen des Einstiegs (P2-8)? Nur die erste
    /// Mission der Region und nur, solange sie nie gewonnen wurde: Wer sie schon
    /// geschafft hat, hat das Bauen und Rufen gelernt.
    func showsIntro(for nodeID: String) -> Bool {
        nodeID == campaign.nodes.first?.id && progress.stars(for: nodeID) == 0
    }

    #if DEBUG
    /// Oberflächentests: Sterne auf einem Knoten, den es noch nicht zu spielen
    /// gibt, damit ein Rang über sechs Sternen prüfbar ist, solange nur
    /// Mission 1 spielbar ist.
    func seedStarsForTests(_ stars: Int, on nodeID: String) {
        guard campaign.node(nodeID) != nil else { return }
        let next = progress.recording(stars: stars, for: nodeID)
        guard next != progress else { return }
        progress = next
        save.progress = next
        persist()
    }

    /// `--e2e-erz N`: Erz für den Schmiede-Test, ohne erst Missionen zu spielen.
    func seedOreForTests(_ amount: Int) {
        guard var changed = avatar, let equipment, let forge = equipment.forge else { return }
        changed.forge = ForgeState(ore: min(amount, forge.maxOre), levels: changed.forge.levels)
        avatar = changed
        save.avatar = changed
        persist()
    }
    #endif

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
