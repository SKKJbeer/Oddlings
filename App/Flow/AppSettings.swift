import Foundation

/// Einstellungen des Geräts, getrennt vom Spielstand (K6): Sie gehören dem
/// Gerät, nicht dem Fortschritt, und überleben ein Zurücksetzen des Spiels.
/// Ton und Musik kommen mit K9; ein Schalter ohne Wirkung steht hier nicht.
enum AppSettings {
    static let vibrationKey = "settings.vibration"

    /// Ohne Eintrag an: Haptik ist Teil der Rückmeldung (07, Abschnitt 5).
    static func vibration(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: vibrationKey) as? Bool ?? true
    }

    static func setVibration(_ on: Bool, in defaults: UserDefaults = .standard) {
        defaults.set(on, forKey: vibrationKey)
    }
}
