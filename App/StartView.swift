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
            VStack(spacing: 20) {
                Text("Oddlings")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                Text("Mission 1")
                    .font(.title3)
                    .opacity(0.8)
                Button { screen = .play } label: {
                    Text("Spielen").font(.title2.bold()).frame(minWidth: 220, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .accessibilityIdentifier("menu.play")
                HStack(spacing: 12) {
                    Button("Vorführung ansehen") { screen = .watch }
                    Button("Leistungsprobe") { screen = .spike }
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.12, green: 0.20, blue: 0.14))
            .foregroundStyle(.white)
            .statusBarHidden()
        case .play:
            BattleView(mode: .play) { screen = .menu }
        case .watch:
            BattleView(mode: .watch) { screen = .menu }
        case .spike:
            SpikeView()
        }
    }
}
