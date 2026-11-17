import SpriteKit
import UIKit

/// Gemalte Markierungen am Boden (A-5, Befund G5): Reichweite und gewählte
/// Zelle. Vorher waren es `SKShapeNode`-Linien, die neben gemalten Türmen wie
/// Entwicklerwerkzeug wirkten.
///
/// Warum kein fertiges Ringbild: Die Reichweiten reichen von gut einer bis über
/// vier Zellen. Ein skaliertes Ringbild hätte bei jedem Turm einen anders dicken
/// Rand. Stattdessen liegt ein gemalter Streifen im Katalog (`mark_ring`, oben
/// Außenkante, unten Innenkante, waagerecht kachelbar), und dieser Typ wickelt
/// ihn zur Laufzeit um den Kreis. So bleibt der Rand bei jeder Größe gleich
/// breit und gleich gemalt. Gerechnet wird einmal je Größe, nicht je Bild.
@MainActor
enum GroundMarks {
    static let stripName = "mark_ring"

    /// Ring für die Reichweite: Radius in Punkten, Rand und Fläche nach BattleStyle.
    static func range(radius: CGFloat, field: CGFloat) -> SKSpriteNode? {
        node(radius: radius, rim: BattleStyle.rangeRim * field, wash: BattleStyle.rangeWash, name: "mark.range")
    }

    /// Ring um die gewählte Zelle, enger und mit stärkerem Schein.
    static func cell(field: CGFloat) -> SKSpriteNode? {
        node(radius: BattleStyle.cellMarkRadius * field, rim: BattleStyle.cellMarkRim * field,
             wash: BattleStyle.cellMarkWash, name: "mark.cell")
    }

    private static func node(radius: CGFloat, rim: CGFloat, wash: CGFloat, name: String) -> SKSpriteNode? {
        guard let texture = texture(radius: radius, rim: rim, wash: wash) else { return nil }
        let sprite = SKSpriteNode(texture: texture)
        sprite.name = name
        let side = 2 * (radius + rim / 2) + 2
        sprite.size = CGSize(width: side, height: side)
        return sprite
    }

    private struct Key: Hashable { let radius: Int, rim: Int, wash: Int }
    private static var cache: [Key: SKTexture] = [:]

    static func texture(radius: CGFloat, rim: CGFloat, wash: CGFloat) -> SKTexture? {
        let key = Key(radius: Int((radius * 4).rounded()), rim: Int((rim * 4).rounded()), wash: Int((wash * 100).rounded()))
        if let cached = cache[key] { return cached }
        guard let strip = strip, let image = render(radius: radius, rim: rim, wash: wash, scale: renderScale, strip: strip) else {
            return nil
        }
        let texture = SKTexture(cgImage: image)
        cache[key] = texture
        return texture
    }

    /// Zweifach reicht: Der Rand ist weich gemalt, die dritte Stufe kostete
    /// das 2,25-Fache an Rechenzeit ohne sichtbaren Gewinn.
    static let renderScale: CGFloat = 2

    /// Streifen als vormultipliziertes RGBA, einmal entpackt.
    struct Strip {
        let width: Int
        let height: Int
        let pixels: [UInt8]
    }

    static let strip: Strip? = {
        guard let image = UIImage(named: stripName)?.cgImage else { return nil }
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? Strip(width: width, height: height, pixels: pixels) : nil
    }()

    /// Wickelt den Streifen um einen Kreis. Innen ein Schein in der Farbe des
    /// Streifens, der zur Mitte hin ausläuft: Die Fläche zeigt, wo der Turm
    /// wirkt, ohne den Boden zuzudecken.
    static func render(radius: CGFloat, rim: CGFloat, wash: CGFloat, scale: CGFloat, strip: Strip) -> CGImage? {
        let r = Double(radius * scale), w = max(2, Double(rim * scale))
        let outer = r + w / 2, inner = r - w / 2
        let side = Int(ceil(2 * outer)) + 4
        let center = Double(side) / 2
        let natural = Double(strip.width) * w / Double(strip.height)
        let repeats = max(1, (2 * Double.pi * r / natural).rounded())
        let washColor = averageColor(strip)
        var out = [UInt8](repeating: 0, count: side * side * 4)
        for y in 0..<side {
            let dy = Double(y) + 0.5 - center
            for x in 0..<side {
                let dx = Double(x) + 0.5 - center
                let d = (dx * dx + dy * dy).squareRoot()
                if d > outer + 1 { continue }
                var px: (Double, Double, Double, Double) = (0, 0, 0, 0)
                if d < inner + 1, inner > 0 {
                    let a = wash * pow(min(1, d / inner), 2)
                    px = (washColor.0 * a, washColor.1 * a, washColor.2 * a, a)
                }
                let v = (outer - d) / w
                if v >= -0.02, v <= 1.02 {
                    var u = (atan2(dy, dx) / (2 * Double.pi) + 0.5) * repeats
                    u -= floor(u)
                    let s = sample(strip, u: u, v: min(1, max(0, v)))
                    // Streifen über den Schein (beides vormultipliziert).
                    px = (s.0 + px.0 * (1 - s.3), s.1 + px.1 * (1 - s.3), s.2 + px.2 * (1 - s.3), s.3 + px.3 * (1 - s.3))
                }
                let i = (y * side + x) * 4
                out[i] = UInt8(min(255, px.0 * 255))
                out[i + 1] = UInt8(min(255, px.1 * 255))
                out[i + 2] = UInt8(min(255, px.2 * 255))
                out[i + 3] = UInt8(min(255, px.3 * 255))
            }
        }
        return out.withUnsafeMutableBytes { buffer in
            CGContext(data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                      space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage()
        }
    }

    /// Bilinear, waagerecht umlaufend; Werte 0 bis 1, vormultipliziert.
    static func sample(_ strip: Strip, u: Double, v: Double) -> (Double, Double, Double, Double) {
        let fx = u * Double(strip.width) - 0.5, fy = v * Double(strip.height - 1)
        let x0 = Int(floor(fx)), y0 = Int(floor(fy))
        let tx = fx - Double(x0), ty = fy - Double(y0)
        func at(_ x: Int, _ y: Int) -> (Double, Double, Double, Double) {
            let xx = ((x % strip.width) + strip.width) % strip.width
            let yy = min(strip.height - 1, max(0, y))
            let i = (yy * strip.width + xx) * 4
            return (Double(strip.pixels[i]) / 255, Double(strip.pixels[i + 1]) / 255,
                    Double(strip.pixels[i + 2]) / 255, Double(strip.pixels[i + 3]) / 255)
        }
        let a = at(x0, y0), b = at(x0 + 1, y0), c = at(x0, y0 + 1), d = at(x0 + 1, y0 + 1)
        func mix(_ p: Double, _ q: Double, _ r: Double, _ s: Double) -> Double {
            (p * (1 - tx) + q * tx) * (1 - ty) + (r * (1 - tx) + s * tx) * ty
        }
        return (mix(a.0, b.0, c.0, d.0), mix(a.1, b.1, c.1, d.1), mix(a.2, b.2, c.2, d.2), mix(a.3, b.3, c.3, d.3))
    }

    /// Mittlere Farbe der deckenden Teile, nicht vormultipliziert.
    static func averageColor(_ strip: Strip) -> (Double, Double, Double) {
        var sum = (0.0, 0.0, 0.0), weight = 0.0
        for i in stride(from: 0, to: strip.pixels.count, by: 4) {
            let a = Double(strip.pixels[i + 3]) / 255
            guard a > 0.5 else { continue }
            sum.0 += Double(strip.pixels[i]) / 255
            sum.1 += Double(strip.pixels[i + 1]) / 255
            sum.2 += Double(strip.pixels[i + 2]) / 255
            weight += a
        }
        guard weight > 0 else { return (1, 0.95, 0.7) }
        return (sum.0 / weight, sum.1 / weight, sum.2 / weight)
    }
}
