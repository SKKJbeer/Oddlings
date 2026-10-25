import SwiftUI
import UIKit

/// Farben, Schriften und Formen der Oberfläche an einer Stelle (07-ui-ux.md,
/// Abschnitt 4). Farben aus `docs/art/art-direction.md` und den Entwürfen;
/// Szenenfarben bleiben in `BattleStyle`. Spielwerte stehen nie hier
/// (Architekturregel 7).
enum UITheme {
    /// Kontur um alles, dunkles Braun statt Schwarz, damit es warm bleibt.
    static let outline = rgb(0x22160F)
    static let wood = rgb(0x2E1F14)
    static let woodRim = rgb(0x4A3122)
    static let woodFace = rgb(0x4A3122)
    static let woodShade = rgb(0x34211A)
    static let goldFace = rgb(0xF2B33D)
    static let goldShade = rgb(0xC9862A)
    /// Text auf Holz: Kontrast 4,5 : 1 oder mehr (07, Abschnitt 6).
    static let cream = rgb(0xFFF4DC)
    static let parchment = rgb(0xE8D8BC)
    static let coin = rgb(0xF2C14E)
    static let heart = rgb(0xD8433A)
    static let danger = rgb(0xF08A24)
    static let fresh = rgb(0x7BD84A)
    static let bolt = rgb(0x4FA8FF)
    static let victory = rgb(0xA82E27)
    static let defeat = rgb(0x7C7F8C)
    static let dim = Color(red: 20 / 255, green: 12 / 255, blue: 7 / 255).opacity(0.62)

    static let line: CGFloat = 3
    static let panelRadius: CGFloat = 22
    static let buttonRadius: CGFloat = 16
    static let barHeight: CGFloat = 40

    /// Schriften aus D-032 in fester Größe: Ein Spiel im Querformat hat keinen
    /// Platz für Dynamic Type, und die Tafeln sind auf diese Größen gebaut.
    static func display(_ size: CGFloat) -> Font { .custom(AppFonts.display, fixedSize: size) }
    static func body(_ size: CGFloat) -> Font { .custom(AppFonts.body, fixedSize: size) }
    static func bodyHeavy(_ size: CGFloat) -> Font { .custom(AppFonts.bodyHeavy, fixedSize: size) }

    /// Bild aus dem Asset-Vertrag, wenn es schon im Katalog liegt. Fehlt es,
    /// zeichnet der Aufrufer die Form aus dem Entwurf im selben Maß.
    static func image(_ name: String) -> UIImage? { UIImage(named: name) }

    private static func rgb(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
    }
}

/// Holztafel: Pause, Ergebnis, Infotafel. Nimmt `ui_panel_wood`, sonst die
/// gezeichnete Form.
struct WoodBackground: View {
    var radius: CGFloat = UITheme.panelRadius

    var body: some View {
        if let picture = UITheme.image("ui_panel_wood") {
            Image(uiImage: picture).resizable()
        } else {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            ZStack {
                shape.fill(UITheme.outline).offset(y: 6)
                shape.fill(UITheme.wood)
                shape.inset(by: UITheme.line).strokeBorder(UITheme.woodRim, lineWidth: UITheme.line)
                shape.strokeBorder(UITheme.outline, lineWidth: UITheme.line)
            }
        }
    }
}

extension View {
    func woodPanel(padding: CGFloat = 20, radius: CGFloat = UITheme.panelRadius) -> some View {
        self.padding(padding)
            .foregroundStyle(UITheme.cream)
            .background(WoodBackground(radius: radius))
    }
}

/// Dicker Knopf aus den Entwürfen: Gold für die Haupthandlung, Holz für den Rest.
struct ChunkyButtonStyle: ButtonStyle {
    enum Kind { case gold, wood }
    var kind: Kind = .wood
    var height: CGFloat = 48
    var fontSize: CGFloat = 18
    var minWidth: CGFloat = 0

    func makeBody(configuration: Configuration) -> some View {
        ChunkyButton(configuration: configuration, style: self)
    }

    private struct ChunkyButton: View {
        let configuration: ButtonStyleConfiguration
        let style: ChunkyButtonStyle
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            let pressed = configuration.isPressed
            let shape = RoundedRectangle(cornerRadius: UITheme.buttonRadius, style: .continuous)
            let gold = style.kind == .gold
            configuration.label
                .font(UITheme.display(style.fontSize))
                .tracking(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(gold ? UITheme.outline : UITheme.cream)
                .padding(.horizontal, 18)
                .frame(minWidth: style.minWidth, minHeight: style.height)
                .background {
                    if let picture = UITheme.image(gold ? "ui_button_gold" : "ui_button_wood") {
                        Image(uiImage: picture).resizable()
                    } else {
                        ZStack {
                            shape.fill(UITheme.outline).offset(y: pressed ? 1 : 4)
                            shape.fill(gold ? UITheme.goldShade : UITheme.woodShade)
                            shape.fill(gold ? UITheme.goldFace : UITheme.woodFace).padding(.bottom, 5)
                            shape.strokeBorder(UITheme.outline, lineWidth: UITheme.line)
                        }
                    }
                }
                .offset(y: pressed ? 3 : 0)
                .opacity(isEnabled ? 1 : 0.45)
                .contentShape(shape)
        }
    }
}

/// Runder Knopf im Kreismenü (54 pt, 07 Grundsatz 5).
struct RingButtonFace<Content: View>: View {
    var highlighted: Bool
    var tint: Color
    var size: CGFloat
    @ViewBuilder var content: Content
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        ZStack {
            Circle().fill(UITheme.outline).offset(y: 3)
            Circle().fill(highlighted ? UITheme.goldFace : UITheme.wood)
            Circle().inset(by: UITheme.line).strokeBorder(highlighted ? UITheme.goldShade : tint, lineWidth: UITheme.line)
            Circle().strokeBorder(UITheme.outline, lineWidth: UITheme.line)
            content
        }
        .frame(width: size, height: size)
        .saturation(isEnabled ? 1 : 0)
        .opacity(isEnabled ? 1 : 0.55)
    }
}
