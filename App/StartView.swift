import SwiftUI

/// Vorläufiger Einstieg, bis es Menüs gibt (Phase 2). Die Leistungsprobe aus
/// WP-01 bleibt erreichbar, bis Steffen auf dem iPhone gemessen hat.
struct StartView: View {
    enum Screen { case menu, battle, spike }

    @State private var screen: Screen

    init() {
        // Der Probelauf in der CI startet direkt die Mission, damit das
        // Bildschirmfoto die Szene zeigt und nicht das Menü.
        _screen = State(initialValue: ProcessInfo.processInfo.arguments.contains("--demo") ? .battle : .menu)
    }

    var body: some View {
        switch screen {
        case .menu:
            VStack(spacing: 16) {
                Text("Oddlings").font(.largeTitle.bold())
                Button("Mission 1 ansehen (Mitspieler)") { screen = .battle }
                Button("Leistungsprobe") { screen = .spike }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.12, green: 0.20, blue: 0.14))
            .foregroundStyle(.white)
            .statusBarHidden()
        case .battle:
            BattleView { screen = .menu }
        case .spike:
            SpikeView()
        }
    }
}
