import CoreText
import SpriteKit
import UIKit

/// Schrift mit dunkler Kontur als **ein** Bild (Review 2, U1, D-211).
///
/// Vorher lagen fünf dunkle Kopien unter der hellen Schrift. SpriteKit blendet
/// jedes Kind einzeln aus: Beim Ein- und Ausblenden schienen die dunklen Kopien
/// durch die halb durchsichtige helle Schrift, und „Welle 3 von 10“ wurde braun.
/// Ein einziges Bild hat nur eine Deckkraft, und die Kontur umläuft die Glyphen
/// gleichmäßig mit runden Ecken statt in fünf Richtungen.
final class OutlinedText: SKSpriteNode {
    /// Gleiche Farbe wie die Kontur der gemalten Figuren (#22160F).
    static let outlineColor = UIColor(red: 0x22 / 255, green: 0x16 / 255, blue: 0x0F / 255, alpha: 1)
    /// Pixel je Punkt der Textur: schärfer als das Gerät, weil Zahlen beim
    /// Aufspringen kurz größer als 1 werden.
    static let textureScale: CGFloat = 3

    private(set) var text: String
    let fontSize: CGFloat
    let fill: UIColor

    init(text: String, fontSize: CGFloat, color: SKColor) {
        self.text = text
        self.fontSize = fontSize
        self.fill = color
        super.init(texture: nil, color: .clear, size: .zero)
        render()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func setText(_ text: String) {
        guard text != self.text else { return }
        self.text = text
        render()
    }

    private func render() {
        let font = UIFont(name: BattleStyle.font, size: fontSize) ?? .boldSystemFont(ofSize: fontSize)
        let drawing = Self.draw(text, font: font, fill: fill)
        texture = SKTexture(image: drawing.image)
        size = drawing.image.size
        anchorPoint = drawing.anchor
    }

    /// Breite der Kontur außerhalb der Glyphen und Versatz des Schattens nach
    /// unten, wie bei der alten Fassung (7 % der Schriftgröße, 1,6-fach tiefer).
    static func outline(for fontSize: CGFloat) -> CGFloat { max(1.2, fontSize * 0.07) }

    /// Zeichnet Schatten, Kontur und Füllung in ein Bild. `anchor` legt den
    /// Mittelpunkt der Glyphen auf den Ursprung des Knotens, wie `.center` beim
    /// `SKLabelNode`, damit Positionen aus der alten Fassung gleich bleiben.
    static func draw(_ text: String, font: UIFont, fill: UIColor) -> (image: UIImage, anchor: CGPoint) {
        let glyphs = path(of: text, font: font)
        let bounds = glyphs.isEmpty ? CGRect(x: 0, y: 0, width: 1, height: 1) : glyphs.boundingBoxOfPath
        let width = outline(for: font.pointSize)
        let drop = width * 1.6
        let pad = width + 1
        let canvas = CGSize(width: ceil(bounds.width + 2 * pad), height: ceil(bounds.height + 2 * pad + drop))
        let format = UIGraphicsImageRendererFormat()
        format.scale = textureScale
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: canvas, format: format).image { context in
            let cg = context.cgContext
            // UIKit zählt y nach unten, die Glyphen nach oben.
            cg.translateBy(x: 0, y: canvas.height)
            cg.scaleBy(x: 1, y: -1)
            cg.translateBy(x: pad - bounds.minX, y: pad + drop - bounds.minY)
            cg.setLineJoin(.round)
            cg.setLineCap(.round)
            cg.setLineWidth(2 * width)
            cg.setStrokeColor(outlineColor.cgColor)
            cg.setFillColor(outlineColor.cgColor)
            // Schatten nach unten, dann Kontur, dann Füllung obenauf.
            cg.saveGState()
            cg.translateBy(x: 0, y: -drop)
            cg.addPath(glyphs)
            cg.drawPath(using: .fillStroke)
            cg.restoreGState()
            cg.addPath(glyphs)
            cg.strokePath()
            cg.setFillColor(fill.cgColor)
            cg.addPath(glyphs)
            cg.fillPath()
        }
        let anchor = CGPoint(x: (pad + bounds.width / 2) / canvas.width,
                             y: (pad + drop + bounds.height / 2) / canvas.height)
        return (image, anchor)
    }

    /// Umrisse aller Glyphen einer Zeile, Grundlinie bei y = 0.
    static func path(of text: String, font: UIFont) -> CGPath {
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
        let path = CGMutablePath()
        guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return path }
        for run in runs {
            let attributes = CTRunGetAttributes(run) as NSDictionary
            // Fehlt ein Zeichen in der Schrift, setzt CoreText eine Ersatzschrift je Lauf ein.
            let runFont = attributes[kCTFontAttributeName as String].map { $0 as! CTFont } ?? (font as CTFont)
            let count = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
            for index in 0..<count {
                guard let glyph = CTFontCreatePathForGlyph(runFont, glyphs[index], nil) else { continue }
                path.addPath(glyph, transform: CGAffineTransform(translationX: positions[index].x, y: positions[index].y))
            }
        }
        return path
    }
}
