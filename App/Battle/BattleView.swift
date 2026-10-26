import OddlingsCore
import SpriteKit
import SwiftUI

/// Eine Mission, gespielt oder vom Mitspieler vorgeführt.
///
/// Kopfleiste oben, darunter die Karte. Szene und Baumenü teilen sich genau
/// einen Rahmen, damit `BoardLayout` in beiden dieselbe Zelle findet.
struct BattleView: View {
    enum Mode { case play, watch }

    @State private var scene: BattleScene
    @State private var controller: BattleController
    @State private var safeArea = EdgeInsets()
    @Environment(\.scenePhase) private var scenePhase
    var onClose: () -> Void

    /// Meldet ein Ergebnis an den Aufrufer (Fortschritt, R-1), mit den Leben,
    /// die übrig sind. Beim Zuschauen bleibt es leer: Eine Vorführung ist kein Sieg.
    var onFinish: ((Outcome, Int) -> Void)?

    init(mission config: BalanceConfig, mode: Mode, onClose: @escaping () -> Void,
         onFinish: ((Outcome, Int) -> Void)? = nil) {
        self.onClose = onClose
        self.onFinish = onFinish
        var autoplay = mode == .watch
        #if DEBUG
        // Der Mitspieler baut auch im eigenen Spiel, damit ein Oberflächentest
        // einen echten Sieg samt Speichern durchspielen kann.
        autoplay = autoplay || ProcessInfo.processInfo.arguments.contains("--e2e-mitspieler")
        #endif
        var config = config
        #if DEBUG
        if let delay = Self.testFirstWaveDelay { config.mission.firstWaveDelay = delay }
        #endif
        let model = BattleModel(config: config, seed: 1, autoplay: autoplay)
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
                    RingMenu(controller: controller, insets: boardInsets)
                    // Nach dem Ende gibt es nichts mehr zu werfen; die Ergebnistafel liegt darüber.
                    if controller.hasAbility && !controller.isFinished {
                        AbilityButton(controller: controller)
                            .padding(.trailing, safeArea.trailing + BattleStyle.hudMargin)
                            .padding(.bottom, safeArea.bottom + BattleStyle.hudMargin)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                    // Tafeln liegen auf der Karte, nicht über der Leiste: Pause
                    // und Tempo bleiben dort bedienbar.
                    BattleOverlay(controller: controller, onRestart: { scene.restart() }, onClose: onClose)
                }
                .ignoresSafeArea(edges: [.horizontal, .bottom])
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("battle.board")
            }
        }
        .onGeometryChange(for: EdgeInsets.self) { $0.safeAreaInsets } action: { safeArea = $0 }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { controller.pauseForBackground() }
        }
        .onChange(of: controller.shownOutcome) { _, outcome in
            if let outcome { onFinish?(outcome, controller.lives) }
        }
    }

    /// Die Karte reicht seitlich und unten unter Kamera und Home-Leiste; das
    /// Kreismenü darf dort nicht liegen. Oben grenzt sie an die Kopfleiste.
    private var boardInsets: HudLayout.Insets {
        HudLayout.Insets(top: 0, left: safeArea.leading, bottom: safeArea.bottom, right: safeArea.trailing)
    }

    #if DEBUG
    /// `--e2e-zeitraffer N` aus den End-zu-End-Tests. Nur im Debug-Bau, damit
    /// kein ausgelieferter Bau einen Schalter für das Spieltempo hat.
    private static var testTimeScale: Double? { positiveArgument(after: "--e2e-zeitraffer") }

    /// `--e2e-erste-welle N`: Tests, die nur bauen und bedienen, halten die
    /// erste Welle zurück. Sonst hängt ihr Ergebnis davon ab, ob der Rechner
    /// schneller ist als die Wartezeit der Mission (Beute wäre Gold, ein Leck
    /// eine Niederlage).
    private static var testFirstWaveDelay: Double? { positiveArgument(after: "--e2e-erste-welle") }

    private static func positiveArgument(after flag: String) -> Double? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return Double(arguments[index + 1]).flatMap { $0 > 0 && $0.isFinite ? $0 : nil }
    }
    #endif
}

/// Steinregen unten rechts (D-033). Schlichter Platzhalter, bis die Oberfläche
/// den Knopf mit Ladering und Zielansicht nach 07 liefert; die Kennung bleibt.
private struct AbilityButton: View {
    let controller: BattleController

    var body: some View {
        Button(action: controller.toggleAim) {
            RingButtonFace(highlighted: controller.aiming, tint: UITheme.parchment, size: BattleStyle.tapTarget) {
                Image(systemName: "circle.hexagongrid.circle.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(UITheme.cream)
                    .opacity(controller.abilityReady ? 1 : 0.35 + 0.65 * controller.abilityCharge)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(BattleTexts.ability)
        .accessibilityValue(BattleTexts.abilityState(ready: controller.abilityReady, aiming: controller.aiming,
                                                     charge: controller.abilityCharge))
        .accessibilityIdentifier("ability")
    }
}
