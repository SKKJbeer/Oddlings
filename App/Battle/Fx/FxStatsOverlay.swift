#if DEBUG
import SwiftUI

/// Zähler der gespielten Effekte für den End-zu-End-Test (`--e2e-fx`, nur
/// Debug-Bau). Die Effekte selbst sind SpriteKit und für XCUITest unsichtbar;
/// so prüft der Test, dass sie in der echten App laufen.
struct FxStatsOverlay: View {
    static let argument = "--e2e-fx"
    let scene: BattleScene

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains(Self.argument) {
            TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                VStack(alignment: .leading, spacing: 0) {
                    Text(scene.fx.stats.summary)
                        .accessibilityIdentifier("fx.stats")
                    // A-5: Turmbilder und Auswahl, ebenfalls SpriteKit.
                    Text(scene.artSummary)
                        .accessibilityIdentifier("scene.art")
                }
                .font(.system(size: 6))
                .opacity(0.02)
            }
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
#endif
