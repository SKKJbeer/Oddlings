import OddlingsCore
import SwiftUI

/// Einstieg der App: zeigt den Schirm, den der `AppFlow` vorgibt
/// (Konzept r-spielrahmen.md, „Schirmfolge"). Die Leistungsprobe aus WP-01
/// bleibt erreichbar, bis Steffen auf dem iPhone gemessen hat.
struct StartView: View {
    @State private var flow: AppFlow
    @State private var showsSettings = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let campaign: CampaignConfig
        do {
            campaign = try CampaignConfig.regionOne()
        } catch {
            // Eine fehlerhafte Regionsdatei ist ein Baufehler; die Kerntests
            // laden dieselbe Datei und fangen ihn vor der Auslieferung.
            fatalError("Region 1 lädt nicht: \(error)")
        }
        // Der Probelauf in der CI startet direkt die Vorführung, damit das
        // Bildschirmfoto die Szene zeigt; die Oberflächentests der Mission
        // starten direkt das eigene Spiel.
        let arguments = ProcessInfo.processInfo.arguments
        var first = campaign.nodes[0].id
        #if DEBUG
        // Oberflächentests einer bestimmten Mission (P2-5: Mission 2 mit Bank).
        if let node = SaveLocation.argument(after: "--e2e-knoten"), campaign.nodes.contains(where: { $0.id == node }) {
            first = node
        }
        #endif
        let screen: AppFlow.Screen = arguments.contains("--demo") ? .watch
            : arguments.contains("--play") ? .battle(node: first) : .menu
        let flow = AppFlow(campaign: campaign, store: SaveLocation.store(), screen: screen)
        #if DEBUG
        // Oberflächentests, die nicht den Aufbau prüfen, beginnen mit fertigem Avatar.
        if flow.avatar == nil, let raw = SaveLocation.argument(after: "--e2e-avatar"), let race = Race(rawValue: raw) {
            flow.createAvatar(race: race, name: "Test", portrait: AvatarPortraits.of(race)[0].id)
        }
        if let node = SaveLocation.argument(after: "--e2e-volle-sterne") { flow.seedStarsForTests(StarRating.maximum, on: node) }
        if let ore = SaveLocation.argument(after: "--e2e-erz").flatMap(Int.init), ore > 0 { flow.seedOreForTests(ore) }
        // Hinweise des Einstiegs (P2-8) liegen in den Voreinstellungen, nicht im
        // Spielstand: Ein frischer Test beginnt auch dort wie eine neue App.
        if arguments.contains("--e2e-frisch") { GuideMemory().reset() }
        if arguments.contains("--e2e-ohne-hinweise") { AppSettings.setGuide(false) }
        #endif
        _flow = State(initialValue: flow)
    }

    var body: some View {
        screen
            .onAppear { updateMusic() }
            .onChange(of: flow.screen) { _, _ in updateMusic() }
            // Im Hintergrund schweigt alles; die Schlacht pausiert dort ohnehin.
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { AudioDirector.shared.suspend() }
                if phase == .active { AudioDirector.shared.resume() }
            }
            #if DEBUG
            .overlay { AudioStatsOverlay() }
            #endif
    }

    /// Menü, Karte, Avatar und Leistungsprobe teilen die Menümusik; die
    /// Schlacht setzt ihre Lage selbst (`BattleView`, Szene).
    private func updateMusic() {
        switch flow.screen {
        case .battle, .watch: break
        case .menu, .setup, .map, .avatar, .spike: AudioDirector.shared.setMood(.menu)
        }
    }

    @ViewBuilder private var screen: some View {
        switch flow.screen {
        case .menu:
            MainMenuView(
                continueTitle: flow.continueNode.map { MenuTexts.continueTitle(CampaignTexts.name($0.id)) },
                continueDetail: flow.continueNode.flatMap { node in
                    flow.mission(for: node.id).map { MenuTexts.waves($0.waves.count) }
                },
                onContinue: { if let node = flow.continueNode { flow.start(node.id) } },
                onPlay: { flow.showMap() }, onWatch: { flow.showWatch() }, onSpike: { flow.showSpike() },
                onSettings: { showsSettings = true },
                avatar: flow.avatar, rank: flow.rank, news: flow.avatarNews,
                onAvatar: { flow.openAvatar() })
            .overlay { if showsSettings { SettingsCard { showsSettings = false } } }
        case .setup:
            AvatarSetupView(flow: flow)
        case .map:
            CampaignMapView(flow: flow)
        case .avatar:
            AvatarScreen(flow: flow)
        case .battle(let node):
            if let mission = flow.battleMission(for: node) {
                BattleView(mission: mission, mode: .play, resume: flow.resume?.node == node ? flow.resume : nil,
                           intro: flow.showsIntro(for: node),
                           onClose: { flow.leaveBattle() },
                           onSuspend: { seed, state in flow.suspend(node, seed: seed, state: state) }) { outcome, lives in
                    flow.finish(node, outcome: outcome, livesLeft: lives)
                    return flow.lastReward
                }
                // Neuer Knoten, neue Schlacht: ohne eigene Kennung behielte
                // SwiftUI den Zustand der vorigen Mission.
                .id(node)
            } else {
                CampaignMapView(flow: flow)
            }
        case .watch:
            if let mission = flow.mission(for: flow.campaign.nodes[0].id) {
                BattleView(mission: mission, mode: .watch, onClose: { flow.showMenu() })
            }
        case .spike:
            SpikeView()
        }
    }
}

enum MenuTexts {
    static func continueTitle(_ mission: String) -> String { "Weiter mit \(mission)" }
    static func waves(_ count: Int) -> String { "\(count) Wellen" }
    static let settings = "Einstellungen"
    static let vibration = "Vibration"
    static let guide = "Hinweise"
    static let done = "Fertig"
    static let sound = "Klänge"
    static let music = "Musik"
    static func percent(_ value: Double) -> String { "\(Int((value * 100).rounded())) %" }
    static let offline = "Oddlings spielt offline und ohne Konto. Musik und Klänge sind frei lizenziert (CC0)."
}
