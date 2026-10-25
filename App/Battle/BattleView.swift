import OddlingsCore
import SpriteKit
import SwiftUI

/// Mission 1 mit dem Mitspieler (WP-11). Bedienung (WP-12) und HUD (WP-13)
/// kommen dazu; bis dahin zeigt die Ansicht nur, was die Simulation tut.
struct BattleView: View {
    @State private var scene: BattleScene
    var onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        let config: BalanceConfig
        do {
            config = try BalanceConfig.missionOne()
        } catch {
            // Eine fehlerhafte Missionsdatei ist ein Baufehler; die Tests
            // fangen ihn, bevor er ausgeliefert wird.
            fatalError("Mission 1 lädt nicht: \(error)")
        }
        _scene = State(initialValue: BattleScene(model: BattleModel(config: config, seed: 1, autoplay: true)))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.ignoresSiblingOrder],
                       debugOptions: [.showsFPS, .showsNodeCount])
                .ignoresSafeArea()
            HStack {
                Button("Zurück", action: onClose)
                Button("Neu starten") { scene.restart() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.black.opacity(0.55))
            .padding(12)
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}
