import SpriteKit
import UIKit

/// Texturen der Effekte unter den Namen des Asset-Vertrags (`fx_*`). Liegt ein
/// Bild im Atlas, nimmt die Szene es; sonst wird die Textur einmal gezeichnet
/// und behalten. Die meisten sind weiß bzw. grau und werden in der Szene
/// eingefärbt, damit ein Bild für Blitzblau und Sporengrün reicht.
@MainActor
enum FxTextures {
    enum Name: String, CaseIterable {
        case glow = "fx_glow"
        case spark = "fx_spark"
        case ring = "fx_ring"
        case puff = "fx_puff"
        case coin = "fx_coin"
        case arrow = "fx_arrow"
        case bolt = "fx_bolt"
        case confetti = "fx_confetti"
        case star = "fx_star"
        case stone = "fx_stone"
        case wall = "fx_wall"
    }

    private static var cache: [Name: SKTexture] = [:]

    static func texture(_ name: Name) -> SKTexture {
        if let cached = cache[name] { return cached }
        let texture = BattleSprites.texture(named: name.rawValue) ?? SKTexture(image: draw(name))
        cache[name] = texture
        return texture
    }

    /// Alle Texturen vorab zeichnen und hochladen. Sonst zeichnet der erste
    /// Münzwurf mitten im Gefecht und das Bild hakt (Probelauf: 842 ms).
    static func prewarm() {
        let all = Name.allCases.map { texture($0) }
        SKTexture.preload(all) {}
    }

    /// Seitenverhältnis Breite zu Höhe, damit Sprites nicht verzerrt werden.
    static func aspect(_ name: Name) -> CGFloat {
        let size = texture(name).size()
        return size.height > 0 ? size.width / size.height : 1
    }

    // MARK: Zeichnen

    /// Kontur wie bei den gemalten Figuren (docs/art/art-direction.md).
    private static let outline = UIColor(red: 0x22 / 255, green: 0x16 / 255, blue: 0x0F / 255, alpha: 1)

    private static func draw(_ name: Name) -> UIImage {
        switch name {
        case .glow: return radial(side: 64, stops: [(0, 1), (0.25, 0.75), (0.6, 0.2), (1, 0)])
        case .spark: return streak(width: 64, height: 14)
        case .ring: return ring(side: 128)
        case .puff: return puff(side: 64)
        case .coin: return coin(side: 48)
        case .arrow: return arrow(width: 96, height: 22)
        case .bolt: return beam(width: 16, height: 32)
        case .star: return star(side: 32)
        case .stone: return stone(side: 48)
        case .wall: return wall(width: 32, height: 112)
        case .confetti: return render(CGSize(width: 12, height: 8)) { context, size in
            context.setFillColor(UIColor.white.cgColor)
            context.addPath(CGPath(roundedRect: CGRect(origin: .zero, size: size), cornerWidth: 2, cornerHeight: 2, transform: nil))
            context.fillPath()
        }
        }
    }

    private static func render(_ size: CGSize, _ body: (CGContext, CGSize) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        // Feste Auflösung statt Bildschirmmaß: Effekte werden ohnehin skaliert,
        // und so sieht jeder Test dieselbe Textur.
        format.scale = 2
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { body($0.cgContext, size) }
    }

    /// Weicher Punkt: Helligkeit über dem Radius.
    private static func radial(side: CGFloat, stops: [(CGFloat, CGFloat)]) -> UIImage {
        render(CGSize(width: side, height: side)) { context, size in
            let colors = stops.map { UIColor(white: 1, alpha: $0.1).cgColor } as CFArray
            let locations = stops.map { $0.0 }
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center,
                                       endRadius: size.width / 2, options: [])
        }
    }

    /// Funke: in Flugrichtung gestreckter, heller Strich.
    private static func streak(width: CGFloat, height: CGFloat) -> UIImage {
        render(CGSize(width: width, height: height)) { context, size in
            context.scaleBy(x: 1, y: size.height / size.width)
            let colors = [UIColor(white: 1, alpha: 1).cgColor, UIColor(white: 1, alpha: 0.5).cgColor,
                          UIColor(white: 1, alpha: 0).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.35, 1]) else { return }
            let center = CGPoint(x: size.width / 2, y: size.width / 2)
            context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center,
                                       endRadius: size.width / 2, options: [])
        }
    }

    /// Ring mit weicher Innenseite, für Druckwelle und Sporenring.
    private static func ring(side: CGFloat) -> UIImage {
        render(CGSize(width: side, height: side)) { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor(white: 1, alpha: 0.25).cgColor,
                          UIColor(white: 1, alpha: 1).cgColor, UIColor(white: 1, alpha: 0).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                            locations: [0.55, 0.85, 0.93, 1]) else { return }
            context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center,
                                       endRadius: size.width / 2, options: [])
        }
    }

    /// Wölkchen: mehrere weiche Kreise, oben heller, unten grauer, damit es
    /// wie die gemalten Figuren Licht von oben hat.
    private static func puff(side: CGFloat) -> UIImage {
        render(CGSize(width: side, height: side)) { context, size in
            let blobs: [(CGFloat, CGFloat, CGFloat)] = [(0.5, 0.55, 0.30), (0.32, 0.5, 0.2), (0.68, 0.5, 0.22),
                                                        (0.42, 0.36, 0.2), (0.6, 0.38, 0.18)]
            for (x, y, r) in blobs {
                let center = CGPoint(x: x * size.width, y: y * size.height)
                let radius = r * size.width
                let shade = 0.78 + 0.22 * (1 - y)
                let colors = [UIColor(white: shade, alpha: 0.95).cgColor, UIColor(white: shade, alpha: 0.6).cgColor,
                              UIColor(white: shade, alpha: 0).cgColor] as CFArray
                guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.6, 1]) else { continue }
                context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center,
                                           endRadius: radius, options: [])
            }
        }
    }

    /// Goldmünze ohne Währungszeichen (Asset-Vertrag, Oberfläche): Rand,
    /// Prägung, Glanzlicht, dunkle Kontur.
    private static func coin(side: CGFloat) -> UIImage {
        render(CGSize(width: side, height: side)) { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
            context.setFillColor(outline.cgColor)
            context.fillEllipse(in: rect)
            context.setFillColor(UIColor(red: 0.80, green: 0.52, blue: 0.10, alpha: 1).cgColor)
            context.fillEllipse(in: rect.insetBy(dx: 2.5, dy: 2.5))
            context.setFillColor(UIColor(red: 1.00, green: 0.80, blue: 0.22, alpha: 1).cgColor)
            context.fillEllipse(in: rect.insetBy(dx: 6, dy: 6))
            context.setFillColor(UIColor(red: 0.95, green: 0.66, blue: 0.14, alpha: 1).cgColor)
            context.fillEllipse(in: rect.insetBy(dx: 12, dy: 12))
            context.setFillColor(UIColor(white: 1, alpha: 0.85).cgColor)
            context.fillEllipse(in: CGRect(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.2,
                                           width: rect.width * 0.22, height: rect.height * 0.14))
        }
    }

    /// Pfeil nach rechts: Holzschaft, Eisenspitze, rote Federn (Farben des Wachturms).
    private static func arrow(width: CGFloat, height: CGFloat) -> UIImage {
        render(CGSize(width: width, height: height)) { context, size in
            let mid = size.height / 2
            context.setLineCap(.round)
            context.setStrokeColor(outline.cgColor)
            context.setLineWidth(5)
            context.move(to: CGPoint(x: 12, y: mid)); context.addLine(to: CGPoint(x: size.width - 16, y: mid))
            context.strokePath()
            context.setStrokeColor(UIColor(red: 0.72, green: 0.52, blue: 0.30, alpha: 1).cgColor)
            context.setLineWidth(2.5)
            context.move(to: CGPoint(x: 12, y: mid)); context.addLine(to: CGPoint(x: size.width - 16, y: mid))
            context.strokePath()
            // Federn
            let fletching = CGMutablePath()
            fletching.move(to: CGPoint(x: 4, y: 2)); fletching.addLine(to: CGPoint(x: 22, y: mid))
            fletching.addLine(to: CGPoint(x: 4, y: size.height - 2)); fletching.addLine(to: CGPoint(x: 12, y: mid))
            fletching.closeSubpath()
            context.addPath(fletching)
            context.setFillColor(UIColor(red: 0.82, green: 0.18, blue: 0.15, alpha: 1).cgColor)
            context.setStrokeColor(outline.cgColor)
            context.setLineWidth(1.5)
            context.drawPath(using: .fillStroke)
            // Spitze
            let head = CGMutablePath()
            head.move(to: CGPoint(x: size.width - 2, y: mid)); head.addLine(to: CGPoint(x: size.width - 20, y: 3))
            head.addLine(to: CGPoint(x: size.width - 16, y: mid)); head.addLine(to: CGPoint(x: size.width - 20, y: size.height - 3))
            head.closeSubpath()
            context.addPath(head)
            context.setFillColor(UIColor(red: 0.80, green: 0.83, blue: 0.88, alpha: 1).cgColor)
            context.drawPath(using: .fillStroke)
        }
    }

    /// Querschnitt eines Strahls: hell in der Mitte, weich zu den Rändern.
    /// Wird in Längsrichtung gestreckt.
    private static func beam(width: CGFloat, height: CGFloat) -> UIImage {
        render(CGSize(width: width, height: height)) { context, size in
            let colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor(white: 1, alpha: 0.55).cgColor,
                          UIColor(white: 1, alpha: 1).cgColor, UIColor(white: 1, alpha: 0.55).cgColor,
                          UIColor(white: 1, alpha: 0).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                            locations: [0, 0.3, 0.5, 0.7, 1]) else { return }
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
        }
    }

    /// Betäubungsstern: fünf Zacken, gold, mit Kontur.
    private static func star(side: CGFloat) -> UIImage {
        render(CGSize(width: side, height: side)) { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = size.width / 2 - 2, inner = outer * 0.45
            let path = CGMutablePath()
            for index in 0..<10 {
                let radius = index % 2 == 0 ? outer : inner
                let angle = CGFloat(index) * .pi / 5 - .pi / 2
                let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            context.addPath(path)
            context.setFillColor(UIColor(red: 1.00, green: 0.86, blue: 0.30, alpha: 1).cgColor)
            context.setStrokeColor(outline.cgColor)
            context.setLineWidth(2)
            context.setLineJoin(.round)
            context.drawPath(using: .fillStroke)
        }
    }

    /// Fels für den Steinregen: grau, eckig gerundet, Licht von oben.
    private static func stone(side: CGFloat) -> UIImage {
        render(CGSize(width: side, height: side)) { context, size in
            let points: [(CGFloat, CGFloat)] = [(0.18, 0.42), (0.34, 0.16), (0.66, 0.12), (0.86, 0.36),
                                                (0.84, 0.70), (0.58, 0.88), (0.26, 0.82), (0.10, 0.62)]
            let path = CGMutablePath()
            for (index, (x, y)) in points.enumerated() {
                let point = CGPoint(x: x * size.width, y: y * size.height)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            context.addPath(path)
            context.setFillColor(UIColor(white: 0.78, alpha: 1).cgColor)
            context.setStrokeColor(outline.cgColor)
            context.setLineWidth(2.5)
            context.setLineJoin(.round)
            context.drawPath(using: .fillStroke)
            // Schattenseite unten, Glanz oben links.
            context.setFillColor(UIColor(white: 0.55, alpha: 1).cgColor)
            context.fillEllipse(in: CGRect(x: size.width * 0.38, y: size.height * 0.56,
                                           width: size.width * 0.38, height: size.height * 0.22))
            context.setFillColor(UIColor(white: 1, alpha: 0.7).cgColor)
            context.fillEllipse(in: CGRect(x: size.width * 0.3, y: size.height * 0.24,
                                           width: size.width * 0.2, height: size.height * 0.12))
        }
    }

    /// Bollwerk von oben: Steinblöcke in einer Reihe, Mörtelfugen, Kontur.
    private static func wall(width: CGFloat, height: CGFloat) -> UIImage {
        render(CGSize(width: width, height: height)) { context, size in
            let blocks = 5
            let gap: CGFloat = 2
            let blockHeight = (size.height - gap * CGFloat(blocks + 1)) / CGFloat(blocks)
            for index in 0..<blocks {
                let inset: CGFloat = index % 2 == 0 ? 2 : 4
                let rect = CGRect(x: inset, y: gap + CGFloat(index) * (blockHeight + gap),
                                  width: size.width - inset * 2, height: blockHeight)
                let path = CGPath(roundedRect: rect, cornerWidth: 4, cornerHeight: 4, transform: nil)
                context.addPath(path)
                context.setFillColor(UIColor(red: 0.66, green: 0.52, blue: 0.38, alpha: 1).cgColor)
                context.setStrokeColor(outline.cgColor)
                context.setLineWidth(2)
                context.drawPath(using: .fillStroke)
                context.setFillColor(UIColor(white: 1, alpha: 0.28).cgColor)
                context.fill(CGRect(x: rect.minX + 3, y: rect.minY + 3, width: rect.width - 6, height: rect.height * 0.25))
            }
        }
    }
}
