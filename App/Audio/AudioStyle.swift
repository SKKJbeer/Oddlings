import Foundation

/// Die Mischung an einer Stelle, wie `FxStyle` für das Bild. Dateien kommen mit
/// Spitze −1 dBFS aus `tools/ton/ton_bauen.py`; hier steht, wie laut sie im
/// Spiel klingen. Wer abmischt, ändert nur diese Datei.
enum AudioStyle {
    struct Mix: Equatable, Sendable {
        /// Fassungen auf der Platte (`stem_1.caf` …).
        var variants: Int
        /// Pegel vor dem Regler, 0…1.
        var gain: Float
        /// Gleichzeitige Stimmen dieses Klangs; darüber entfällt er.
        var voices: Int
        /// Mindestabstand zwischen zwei Starts in Sekunden.
        var spacing: Double
        /// Tonhöhenstreuung in Halbtönen (±), gegen den Maschinengewehr-Klang.
        var spread: Float
    }

    static func mix(_ cue: SoundCue) -> Mix {
        switch cue {
        case .uiTap: Mix(variants: 2, gain: 0.35, voices: 2, spacing: 0.03, spread: 0.5)
        case .uiConfirm: Mix(variants: 1, gain: 0.5, voices: 1, spacing: 0.1, spread: 0)
        case .uiDeny: Mix(variants: 1, gain: 0.55, voices: 1, spacing: 0.15, spread: 0)
        case .build: Mix(variants: 2, gain: 0.85, voices: 2, spacing: 0.05, spread: 1)
        case .sell: Mix(variants: 1, gain: 0.7, voices: 2, spacing: 0.05, spread: 1)
        case .watchShot: Mix(variants: 3, gain: 0.3, voices: 4, spacing: 0.04, spread: 2)
        case .boltShot: Mix(variants: 2, gain: 0.4, voices: 3, spacing: 0.05, spread: 1)
        case .sporePuff: Mix(variants: 2, gain: 0.45, voices: 3, spacing: 0.08, spread: 1.5)
        case .combo: Mix(variants: 1, gain: 0.55, voices: 2, spacing: 0.08, spread: 1)
        case .hit: Mix(variants: 2, gain: 0.22, voices: 4, spacing: 0.05, spread: 2.5)
        case .slowed: Mix(variants: 1, gain: 0.3, voices: 2, spacing: 0.15, spread: 2)
        case .enemyPop: Mix(variants: 3, gain: 0.55, voices: 4, spacing: 0.03, spread: 2)
        case .coin: Mix(variants: 1, gain: 0.25, voices: 2, spacing: 0.08, spread: 1.5)
        case .leak: Mix(variants: 1, gain: 0.9, voices: 2, spacing: 0.1, spread: 0.5)
        case .wave: Mix(variants: 1, gain: 0.7, voices: 1, spacing: 1, spread: 0)
        case .abilityCast: Mix(variants: 1, gain: 0.6, voices: 1, spacing: 0.2, spread: 0)
        case .stoneImpact: Mix(variants: 2, gain: 0.95, voices: 1, spacing: 0.2, spread: 0.5)
        case .moonImpact: Mix(variants: 1, gain: 0.85, voices: 1, spacing: 0.2, spread: 0)
        case .wallUp: Mix(variants: 1, gain: 0.8, voices: 1, spacing: 0.2, spread: 0)
        case .wallDown: Mix(variants: 1, gain: 0.7, voices: 1, spacing: 0.2, spread: 0)
        }
    }

    /// Aufwerten klingt wie Bauen, eine Quarte höher: dasselbe Handwerk, mehr davon.
    static let upgradeSemitones: Float = 5

    /// Ein Treffer an der Panzerung klingt eine Quinte tiefer als einer ins Fleisch.
    static let armorSemitones: Float = -7

    /// Alles, was der Moorkönig auslöst, eine Quarte tiefer (P3-4): schwer und fremd.
    static let bossSemitones: Float = -5

    /// Tonhöhenstufe je Kettenglied des Blitzes („Knistern, je Sprung höher").
    static let boltStepSemitones: Float = 1
    /// Höchstens so viele Stufen, damit lange Ketten nicht quietschen.
    static let boltMaxSteps = 4

    /// Musik unter den Klängen: Sie trägt, ohne zu übertönen.
    static let musicGain: Float = 0.7
    /// Pause dämpft die Musik auf diesen Anteil, statt sie abzuschneiden.
    static let pauseDuck: Float = 0.35
    static let crossfade: TimeInterval = 1.2
    static let fadeOut: TimeInterval = 0.6

    /// Spieler im Pool; ist keiner frei, entfällt der Klang.
    static let voices = 16

    /// Vorgaben der Regler (K6: Gerät, nicht Spielstand).
    static let defaultSound: Double = 0.8
    static let defaultMusic: Double = 0.6
}
