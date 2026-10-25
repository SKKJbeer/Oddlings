import OddlingsCore
import SpriteKit
import SwiftUI

/// Mission 1, gespielt oder vom Mitspieler vorgeführt.
///
/// Kopfleiste oben, darunter die Karte. Szene und Baumenü teilen sich genau
/// einen Rahmen, damit `BoardLayout` in beiden dieselbe Zelle findet.
struct BattleView: View {
    enum Mode { case play, watch }

    @State private var scene: BattleScene
    @State private var controller: BattleController
    @Environment(\.scenePhase) private var scenePhase
    var onClose: () -> Void

    init(mode: Mode, onClose: @escaping () -> Void) {
        self.onClose = onClose
        let config: BalanceConfig
        do {
            config = try BalanceConfig.missionOne()
        } catch {
            // Eine fehlerhafte Missionsdatei ist ein Baufehler; die Tests
            // fangen ihn, bevor er ausgeliefert wird.
            fatalError("Mission 1 lädt nicht: \(error)")
        }
        let model = BattleModel(config: config, seed: 1, autoplay: mode == .watch)
        #if DEBUG
        model.timeScale = Self.testTimeScale ?? 1
        #endif
        let controller = BattleController(model: model, interactive: mode == .play)
        let scene = BattleScene(model: model)
        scene.controller = controller
        _scene = State(initialValue: scene)
        _controller = State(initialValue: controller)
    }

    var body: some View {
        ZStack {
            Color(uiColor: BattleStyle.background).ignoresSafeArea()
            VStack(spacing: BattleStyle.hudMargin) {
                BattleTopBar(controller: controller, onClose: onClose)
                    .padding([.horizontal, .top], BattleStyle.hudMargin)
                ZStack {
                    SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.ignoresSiblingOrder])
                    BattleMenu(controller: controller)
                }
                .ignoresSafeArea(edges: [.horizontal, .bottom])
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("battle.board")
            }
            BattleOverlay(controller: controller, onRestart: { scene.restart() }, onClose: onClose)
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { controller.pauseForBackground() }
        }
    }

    #if DEBUG
    /// `--e2e-zeitraffer N` aus den End-zu-End-Tests. Nur im Debug-Bau, damit
    /// kein ausgelieferter Bau einen Schalter für das Spieltempo hat.
    private static var testTimeScale: Double? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--e2e-zeitraffer"), index + 1 < arguments.count else { return nil }
        return Double(arguments[index + 1]).flatMap { $0 > 0 ? $0 : nil }
    }
    #endif
}
