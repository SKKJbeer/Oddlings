import OddlingsCore
import SwiftUI

/// Einstieg der App: zeigt den Schirm, den der `AppFlow` vorgibt
/// (Konzept r-spielrahmen.md, „Schirmfolge"). Die Leistungsprobe aus WP-01
/// bleibt erreichbar, bis Steffen auf dem iPhone gemessen hat.
struct StartView: View {
    @State private var flow: AppFlow
    @State private var showsSettings = false

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
        let first = campaign.nodes[0].id
        let screen: AppFlow.Screen = arguments.contains("--demo") ? .watch
            : arguments.contains("--play") ? .battle(node: first) : .menu
        let flow = AppFlow(campaign: campaign, store: SaveLocation.store(), screen: screen)
        #if DEBUG
        // Oberflächentests, die nicht den Aufbau prüfen, beginnen mit fertigem Avatar.
        if flow.avatar == nil, let raw = SaveLocation.argument(after: "--e2e-avatar"), let race = Race(rawValue: raw) {
            flow.createAvatar(race: race, name: "Test", portrait: AvatarPortraits.of(race)[0].id)
        }
        #endif
        _flow = State(initialValue: flow)
    }

    var body: some View {
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
                avatar: flow.avatar, rank: flow.rank, newTalent: flow.newTalentWaiting,
                onAvatar: { flow.openAvatarPanel() })
            .overlay { if showsSettings { SettingsCard { showsSettings = false } } }
            .overlay { if flow.showsAvatarPanel { AvatarPanel(flow: flow) { flow.closeAvatarPanel() } } }
        case .setup:
            AvatarSetupView(flow: flow)
        case .map:
            CampaignMapView(flow: flow)
                .overlay { if flow.showsAvatarPanel { AvatarPanel(flow: flow) { flow.closeAvatarPanel() } } }
        case .battle(let node):
            if let mission = flow.battleMission(for: node) {
                BattleView(mission: mission, mode: .play, onClose: { flow.showMap() }) { outcome, lives in
                    flow.finish(node, outcome: outcome, livesLeft: lives)
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
    static let done = "Fertig"
    static let soundLater = "Klänge und Musik kommen mit dem Ton. Oddlings spielt offline und ohne Konto."
}
