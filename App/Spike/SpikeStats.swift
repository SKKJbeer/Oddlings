import Observation

/// Werte für das HUD. Die Szene setzt sie zweimal je Sekunde, nicht in jedem
/// Bild: Genau das ist die Probe, ob ein SwiftUI-HUD über SpriteKit die
/// Bildrate in Ruhe lässt (Risiko T3).
@MainActor
@Observable
final class SpikeStats {
    var averageFPS: Double = 0
    /// Längstes Bild der letzten Messperiode in Millisekunden. Ruckler zeigt
    /// dieser Wert, nicht der Durchschnitt.
    var worstFrameMS: Double = 0
    var spriteCount: Int = 0
    var updates: Int = 0

    var targetSpriteCount: Int = 300
    var lightningEnabled: Bool = true
}
