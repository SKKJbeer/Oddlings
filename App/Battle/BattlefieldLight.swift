import SpriteKit

/// Lichtton je Kampfplatz (D-120). Der gemalte Boden ist beim Malen mit diesem
/// Ton multipliziert worden (`LICHT` in art/karten/ENTSTEHUNG.md); Türme und
/// Festung bekommen denselben, sonst stehen sie in der Dämmerung im Mittagslicht.
/// Der Wert ist Darstellung, kein Spielwert, und liegt deshalb bei der App,
/// in `kampfplatzlicht.json`. tools/art-check hält beide Stellen gleich.
@MainActor
enum BattlefieldLight {
    /// Mission → Farbe; fehlt ein Eintrag, bleibt der Turm ungetönt.
    static let table: [String: SKColor] = {
        guard let url = Bundle.main.url(forResource: "kampfplatzlicht", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return parse(data)
    }()

    static func color(missionID: String) -> SKColor? { table[missionID] }

    /// Nur Einträge `mission-…` mit drei Werten 0…255; alles andere (auch der
    /// Kommentar `_zweck`) wird übergangen statt die ganze Tabelle zu verwerfen.
    static func parse(_ data: Data) -> [String: SKColor] {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        var result: [String: SKColor] = [:]
        for (key, value) in object where key.hasPrefix("mission-") {
            guard let rgb = value as? [Int], rgb.count == 3, rgb.allSatisfy({ (0...255).contains($0) }) else { continue }
            result[key] = SKColor(red: CGFloat(rgb[0]) / 255, green: CGFloat(rgb[1]) / 255,
                                  blue: CGFloat(rgb[2]) / 255, alpha: 1)
        }
        return result
    }
}
