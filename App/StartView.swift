import SwiftUI

/// Vorläufiger Einstieg, bis es Menüs gibt (Phase 2). Die Leistungsprobe aus
/// WP-01 bleibt erreichbar, bis Steffen auf dem iPhone gemessen hat.
struct StartView: View {
    enum Screen { case menu, play, watch, spike }

    @State private var screen: Screen

    init() {
        // Der Probelauf in der CI startet direkt die Vorführung, damit das
        // Bildschirmfoto die Szene zeigt; der Oberflächentest startet direkt
        // das eigene Spiel.
        let arguments = ProcessInfo.processInfo.arguments
        _screen = State(initialValue: arguments.contains("--demo") ? .watch : arguments.contains("--play") ? .play : .menu)
    }

    var body: some View {
        switch screen {
        case .menu:
            MainMenuView(onPlay: { screen = .play }, onWatch: { screen = .watch }, onSpike: { screen = .spike })
        case .play:
            BattleView(mode: .play) { screen = .menu }
        case .watch:
            BattleView(mode: .watch) { screen = .menu }
        case .spike:
            SpikeView()
        }
    }
}
