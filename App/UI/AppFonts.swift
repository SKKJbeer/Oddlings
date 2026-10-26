import CoreText
import Foundation

/// Die Schriften aus D-032. Sie liegen im App-Bündel und werden beim Start
/// angemeldet, statt über `UIAppFonts` in der Info.plist: Die Plist erzeugt
/// Xcode (GENERATE_INFOPLIST_FILE), und eine Liste dort wäre eine zweite
/// Stelle, die beim Tausch einer Datei vergessen wird.
enum AppFonts {
    /// PostScript-Namen, wie in den Dateien.
    static let display = "LilitaOne"
    static let body = "Nunito-Bold"
    static let bodyHeavy = "Nunito-ExtraBold"

    static let all = [display, body, bodyHeavy]

    /// Meldet jede TTF im Bündel an. Zweimal anmelden ist harmlos: CoreText
    /// lehnt das zweite Mal ab, die Schrift bleibt nutzbar.
    static func register(bundle: Bundle = .main) {
        for url in bundle.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
