import OddlingsCore
import SwiftUI

/// Kreismenü am Feld (D-031, 07-ui-ux.md „Bauen“ und „Turm antippen“).
/// Zeichnet nur; wo Knöpfe und Infotafel liegen, rechnet `HudLayout`, und was
/// ein Tipp bewirkt, entscheidet der `BattleController`. Die Mission läuft
/// weiter, während das Menü offen ist (D-019).
struct RingMenu: View {
    let controller: BattleController
    /// Sichere Ränder der Karte (Dynamic Island, Home-Leiste).
    var insets: HudLayout.Insets

    var body: some View {
        GeometryReader { geometry in
            let board = BoardLayout(size: geometry.size, map: controller.map)
            // Was die Ansicht selbst meldet, gilt zusätzlich: Je nach Aufbau
            // kommt der sichere Bereich hier oder nur an der Wurzel an.
            let own = geometry.safeAreaInsets
            let edges = HudLayout.Insets(top: max(insets.top, own.top), left: max(insets.left, own.leading),
                                         bottom: max(insets.bottom, own.bottom), right: max(insets.right, own.trailing))
            let hud = HudLayout(board: board, insets: edges, metrics: BattleStyle.hudMetrics)
            if let cell = controller.anchorCell {
                menu(at: cell, hud: hud)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("battle.menu")
            }
        }
    }

    @ViewBuilder private func menu(at cell: Cell, hud: HudLayout) -> some View {
        switch controller.selection {
        case .none:
            EmptyView()
        case .cell(_, let choice):
            let kinds = TowerKind.allCases
            let points = hud.ring(at: cell, count: kinds.count)
            ZStack {
                if let choice {
                    let rect = hud.panel(for: cell, avoiding: points)
                    InfoPanel(kind: choice, action: BattleTexts.tapAgainToBuild, actionID: nil)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
                ForEach(kinds.indices, id: \.self) { index in
                    if index < points.count {
                        TowerRingButton(controller: controller, kind: kinds[index], chosen: choice == kinds[index])
                            .position(points[index])
                    }
                }
            }
        case .tower(_, let armed):
            if let tower = controller.selectedTower {
                let points = hud.ring(at: cell, count: 1)
                let rect = hud.panel(for: cell, avoiding: points)
                let refund = controller.refund(for: tower)
                ZStack {
                    InfoPanel(kind: tower.kind,
                              action: armed ? BattleTexts.confirmSell(refund: refund) : BattleTexts.refundLine(refund),
                              actionID: armed ? "sell.confirm" : nil)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    if let point = points.first {
                        SellRingButton(refund: refund, armed: armed, action: controller.sell)
                            .position(point)
                    }
                }
            }
        }
    }
}

/// Ein Turmknopf im Bogen: Bild des Turms, darunter das Preisschild.
private struct TowerRingButton: View {
    let controller: BattleController
    let kind: TowerKind
    let chosen: Bool

    var body: some View {
        let affordable = controller.canAfford(kind)
        let missing = controller.missingGold(for: kind)
        Button { controller.choose(kind) } label: {
            RingButtonFace(highlighted: chosen, tint: RingMenuStyle.tint(kind), size: BattleStyle.ringButton) {
                TowerPicture(kind: kind)
                    .padding(6)
                    .saturation(affordable ? 1 : 0.2)
                    .opacity(affordable ? 1 : 0.6)
            }
            .overlay(alignment: .bottom) {
                PriceTag(text: chosen ? BattleTexts.build
                                      : affordable ? "\(controller.cost(of: kind))" : BattleTexts.missing(missing),
                         coin: affordable && !chosen, warn: !affordable)
                    .offset(y: 11)
            }
        }
        .buttonStyle(RingPressStyle())
        .accessibilityLabel(chosen ? "\(BattleTexts.build), \(BattleTexts.name(kind))"
                                   : affordable ? "\(BattleTexts.name(kind)), \(BattleTexts.price(controller.cost(of: kind)))"
                                                : "\(BattleTexts.name(kind)), \(BattleTexts.missing(missing))")
        .accessibilityIdentifier("build.\(kind.rawValue)")
    }
}

private struct SellRingButton: View {
    let refund: Int
    let armed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RingButtonFace(highlighted: armed, tint: UITheme.coin, size: BattleStyle.ringButton) {
                VStack(spacing: 0) {
                    if armed {
                        Text(BattleTexts.sellArmed).font(UITheme.display(15))
                    } else {
                        Image(systemName: "arrow.uturn.down").font(.system(size: 15, weight: .heavy))
                        Text("+\(refund)").font(UITheme.display(15))
                    }
                }
                .foregroundStyle(armed ? UITheme.outline : UITheme.coin)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(4)
            }
        }
        .buttonStyle(RingPressStyle())
        .accessibilityLabel(armed ? "\(BattleTexts.sellArmed) \(BattleTexts.sell(refund: refund))"
                                  : BattleTexts.sell(refund: refund))
        .accessibilityIdentifier("sell")
    }
}

/// Name, Rolle, Zusammenspiel und was das nächste Tippen tut.
private struct InfoPanel: View {
    let kind: TowerKind
    let action: String
    let actionID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(BattleTexts.name(kind)).font(UITheme.display(19))
            Text(BattleTexts.role(kind)).font(UITheme.body(13)).foregroundStyle(UITheme.parchment)
            Text(BattleTexts.combo(kind)).font(UITheme.body(13)).foregroundStyle(UITheme.fresh)
            actionLine
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .woodPanel(padding: 12, radius: 18)
        .allowsHitTesting(false)
    }

    @ViewBuilder private var actionLine: some View {
        let text = Text(action).font(UITheme.bodyHeavy(13)).foregroundStyle(UITheme.coin)
        if let actionID { text.accessibilityIdentifier(actionID) } else { text }
    }
}

private struct PriceTag: View {
    let text: String
    let coin: Bool
    let warn: Bool

    var body: some View {
        HStack(spacing: 3) {
            if coin { Circle().fill(UITheme.coin).frame(width: 8, height: 8) }
            Text(text).font(UITheme.display(12))
        }
        .padding(.horizontal, 7)
        .frame(height: 18)
        .foregroundStyle(warn ? UITheme.outline : UITheme.cream)
        .background(warn ? UITheme.danger : UITheme.outline, in: Capsule())
        .overlay(Capsule().strokeBorder(UITheme.outline, lineWidth: 2))
        .fixedSize()
    }
}

/// Gemaltes Turmbild aus dem Katalog; `ui_tower_*` hat Vorrang, sobald es da ist.
private struct TowerPicture: View {
    let kind: TowerKind

    var body: some View {
        if let picture = UITheme.image("ui_tower_\(kind.rawValue)") ?? UITheme.image(BattleSprites.towerName(kind)) {
            Image(uiImage: picture).resizable().scaledToFit()
        } else {
            Circle().fill(RingMenuStyle.tint(kind)).padding(8)
        }
    }
}

/// Knopf sinkt beim Drücken leicht ein.
private struct RingPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.92 : 1)
    }
}

enum RingMenuStyle {
    /// Rollenfarbe am Knopfrand (07, Grundsatz 6).
    static func tint(_ kind: TowerKind) -> Color {
        switch kind {
        case .watch: UITheme.heart
        case .lightning: UITheme.bolt
        case .spore: UITheme.fresh
        }
    }
}
