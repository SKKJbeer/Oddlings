#if DEBUG
import SwiftUI

/// Zähler der gespielten Klänge und der Musiklage für den End-zu-End-Test
/// (`--e2e-ton`, nur Debug-Bau). Ton ist für XCUITest unhörbar; so prüft der
/// Test, dass die echte App ihn auslöst. Gegenstück zu `FxStatsOverlay`.
struct AudioStatsOverlay: View {
    static let argument = "--e2e-ton"

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains(Self.argument) {
            TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                Text(AudioDirector.shared.stats.summary)
                    .font(.system(size: 6))
                    .opacity(0.02)
                    .accessibilityIdentifier("audio.stats")
            }
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}
#endif
