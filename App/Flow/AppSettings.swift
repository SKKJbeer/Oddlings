import Foundation

/// Einstellungen des Geräts, getrennt vom Spielstand (K6): Sie gehören dem
/// Gerät, nicht dem Fortschritt, und überleben ein Zurücksetzen des Spiels.
enum AppSettings {
    static let vibrationKey = "settings.vibration"
    static let soundKey = "settings.sound"
    static let musicKey = "settings.music"
    static let guideKey = "settings.guide"

    /// Ohne Eintrag an: Haptik ist Teil der Rückmeldung (07, Abschnitt 5).
    static func vibration(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: vibrationKey) as? Bool ?? true
    }

    static func setVibration(_ on: Bool, in defaults: UserDefaults = .standard) {
        defaults.set(on, forKey: vibrationKey)
    }

    /// Hinweise des Einstiegs (P2-8). Ohne Eintrag an: Wer neu ist, weiß nicht,
    /// dass es sie gibt. Wer sie ausschaltet, sieht keins mehr.
    static func guide(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: guideKey) as? Bool ?? true
    }

    static func setGuide(_ on: Bool, in defaults: UserDefaults = .standard) {
        defaults.set(on, forKey: guideKey)
    }

    /// Lautstärke der Klänge, 0…1 (P2-3).
    static func soundVolume(in defaults: UserDefaults = .standard) -> Double {
        volume(forKey: soundKey, default: AudioStyle.defaultSound, in: defaults)
    }

    static func setSoundVolume(_ value: Double, in defaults: UserDefaults = .standard) {
        defaults.set(clamped(value), forKey: soundKey)
    }

    /// Lautstärke der Musik, 0…1 (P2-3).
    static func musicVolume(in defaults: UserDefaults = .standard) -> Double {
        volume(forKey: musicKey, default: AudioStyle.defaultMusic, in: defaults)
    }

    static func setMusicVolume(_ value: Double, in defaults: UserDefaults = .standard) {
        defaults.set(clamped(value), forKey: musicKey)
    }

    /// Was in den Voreinstellungen steht, kommt von außen (Sicherung, Profil):
    /// Ein Wert außerhalb 0…1 oder keine Zahl wird begrenzt bzw. verworfen.
    private static func volume(forKey key: String, default fallback: Double, in defaults: UserDefaults) -> Double {
        guard let value = defaults.object(forKey: key) as? Double, value.isFinite else { return fallback }
        return clamped(value)
    }

    private static func clamped(_ value: Double) -> Double {
        value.isFinite ? min(max(value, 0), 1) : 0
    }
}
