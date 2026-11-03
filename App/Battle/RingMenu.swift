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
        case .none, .aiming:
            EmptyView()
        case .cell(_, let choice):
            let kinds = controller.buildable
            let points = hud.ring(at: cell, count: kinds.count)
            ZStack {
                if let choice {
                    let rect = hud.panel(for: cell, avoiding: points)
                    InfoPanel(title: BattleTexts.name(choice), lines: previewLines(choice), action: BattleTexts.tapAgainToBuild, actionID: nil)
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
        case .tower(_, let armed, let upgradeArmed, _):
            if let tower = controller.selectedTower {
                let choices = controller.specializations(for: tower)
                // Zwei zur Wahl (P3-3, S15): je ein Stern statt „Aufwerten“.
                let stars = choices.count > 1 ? choices : []
                let upgradeCost = stars.isEmpty ? controller.upgradeCost(for: tower) : nil
                let targets = controller.hasTargetMode(tower)
                // Reihenfolge im Bogen: Aufwerten (oder die Sterne), Zielwahl, Verkaufen (07, „Turm antippen“).
                let buyButtons = stars.isEmpty ? (upgradeCost == nil ? 0 : 1) : stars.count
                let count = 1 + buyButtons + (targets ? 1 : 0)
                let points = hud.ring(at: cell, count: count)
                let rect = hud.panel(for: cell, avoiding: points)
                let refund = controller.refund(for: tower)
                ZStack {
                    InfoPanel(title: tower.specialization.map(BattleTexts.name) ?? BattleTexts.name(tower.kind, level: tower.level),
                              lines: towerLines(tower, upgradeArmed: upgradeArmed),
                              action: actionLine(tower, armed: armed, upgradeArmed: upgradeArmed, refund: refund),
                              actionID: armed ? "sell.confirm"
                                  : upgradeArmed ? (controller.specialization(for: tower) == nil ? "upgrade.confirm" : "specialize.confirm") : nil)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    if let upgradeCost, let point = points.first {
                        UpgradeRingButton(cost: upgradeCost, armed: upgradeArmed,
                                          affordable: controller.gold >= upgradeCost,
                                          specialization: controller.specialization(for: tower),
                                          action: controller.upgrade)
                            .position(point)
                    }
                    ForEach(stars.indices, id: \.self) { index in
                        let star = stars[index]
                        let cost = controller.cost(of: star) ?? 0
                        if index < points.count {
                            UpgradeRingButton(cost: cost, armed: upgradeArmed && controller.armedSpecialization == star,
                                              affordable: controller.gold >= cost, specialization: star,
                                              identifier: "specialize.\(star.rawValue)",
                                              action: { controller.specialize(star) })
                                .position(points[index])
                        }
                    }
                    if targets, points.count >= 2 {
                        TargetRingButton(mode: tower.targetMode, action: controller.cycleTargetMode)
                            .position(points[points.count - 2])
                    }
                    if let point = points.last {
                        SellRingButton(refund: refund, armed: armed, action: controller.sell)
                            .position(point)
                    }
                }
            }
        }
    }
}

extension RingMenu {
    /// Zweite und dritte Zeile der Infotafel vor dem Bau. Bei der Bank steht
    /// der Preis des Wartens in Orange da (07, „Zwergenbank“).
    fileprivate func previewLines(_ kind: TowerKind) -> InfoLines {
        guard kind == .bank, let bank = controller.bank else {
            return InfoLines(first: BattleTexts.role(kind), second: BattleTexts.combo(kind))
        }
        return InfoLines(first: BattleTexts.bankIncome(bank), second: BattleTexts.bankWarning(cost: bank.cost), warn: true)
    }

    /// Bei einem gebauten Turm; die Bank zeigt, wie viel sie ausgezahlt hat.
    /// Vor dem Aufwerten sagt die Tafel, was Stufe 2 bringt, danach die Zielwahl.
    fileprivate func towerLines(_ tower: Tower, upgradeArmed: Bool) -> InfoLines {
        if upgradeArmed, let specialization = controller.armedSpecialization {
            let others = controller.specializations(for: tower).filter { $0 != specialization }
            return InfoLines(first: BattleTexts.effect(specialization),
                             second: others.first.map(BattleTexts.specializeDrops) ?? BattleTexts.specializeFinal, warn: true)
        }
        if controller.specializations(for: tower).count > 1 {
            return InfoLines(first: BattleTexts.chooseSpecialization, second: BattleTexts.role(tower.kind))
        }
        if upgradeArmed {
            return InfoLines(first: BattleTexts.upgradeArmed,
                             second: tower.kind == .spore ? BattleTexts.upgradeUnlocksNothing : BattleTexts.upgradeUnlocks)
        }
        if controller.hasTargetMode(tower) {
            return InfoLines(first: BattleTexts.role(tower.kind), second: BattleTexts.targetLine(tower.targetMode))
        }
        guard tower.kind == .bank, let bank = controller.bank else {
            return InfoLines(first: BattleTexts.role(tower.kind), second: BattleTexts.combo(tower.kind))
        }
        if controller.isEmpty(tower) { return InfoLines(first: BattleTexts.bankEmpty, second: BattleTexts.role(.bank)) }
        return InfoLines(first: BattleTexts.bankPaid(tower.paid, of: bank.cap), second: BattleTexts.bankIncome(bank))
    }

    /// Was das nächste Tippen tut: verkaufen, aufwerten oder der Erlös.
    fileprivate func actionLine(_ tower: Tower, armed: Bool, upgradeArmed: Bool, refund: Int) -> String {
        if armed { return BattleTexts.confirmSell(refund: refund) }
        if upgradeArmed, let specialization = controller.armedSpecialization, let cost = controller.cost(of: specialization) {
            return BattleTexts.confirmSpecialize(specialization, cost: cost)
        }
        if let specialization = controller.specialization(for: tower), let cost = controller.upgradeCost(for: tower) {
            return controller.specializations(for: tower).count > 1 ? BattleTexts.chooseOneStar
                                                                      : BattleTexts.specializeLine(specialization, cost: cost)
        }
        if upgradeArmed, let cost = controller.upgradeCost(for: tower) { return BattleTexts.confirmUpgrade(cost) }
        if let cost = controller.upgradeCost(for: tower) { return BattleTexts.upgradeLine(cost) }
        return BattleTexts.refundLine(refund)
    }
}

/// Rolle und Zusammenspiel, bei der Bank Ertrag und Warnung.
fileprivate struct InfoLines {
    var first: String
    var second: String
    /// Zweite Zeile in Orange statt Grün: ein Preis, kein Vorteil.
    var warn = false
}

/// Ein Turmknopf im Bogen: Bild des Turms, darunter das Preisschild.
private struct TowerRingButton: View {
    let controller: BattleController
    let kind: TowerKind
    let chosen: Bool

    var body: some View {
        let affordable = controller.canAfford(kind)
        let missing = controller.missingGold(for: kind)
        // Höchstzahl erreicht: gedimmt, das Schild zeigt „2/2“ statt des Preises (07).
        let full = controller.atLimit(kind)
        let usable = affordable && !full
        Button { controller.choose(kind) } label: {
            RingButtonFace(highlighted: chosen, tint: RingMenuStyle.tint(kind), size: BattleStyle.ringButton) {
                TowerPicture(kind: kind)
                    .padding(6)
                    .saturation(usable ? 1 : 0.2)
                    .opacity(usable ? 1 : 0.6)
            }
            .overlay(alignment: .bottom) {
                PriceTag(text: full ? controller.limitTag
                               : chosen ? BattleTexts.build
                               : affordable ? "\(controller.cost(of: kind))" : BattleTexts.missing(missing),
                         coin: usable && !chosen, warn: !affordable && !full)
                    .offset(y: 11)
            }
        }
        .buttonStyle(RingPressStyle())
        .accessibilityLabel(full ? "\(BattleTexts.name(kind)), \(controller.limitReachedText)"
                                 : chosen ? "\(BattleTexts.build), \(BattleTexts.name(kind))"
                                 : affordable ? "\(BattleTexts.name(kind)), \(BattleTexts.price(controller.cost(of: kind)))"
                                              : "\(BattleTexts.name(kind)), \(BattleTexts.missing(missing))")
        .accessibilityValue(full ? controller.limitTag : "")
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

/// Aufwerten: Pfeil nach oben mit Preis, beim ersten Tippen das neue
/// Stufenschild wie „Sicher?“ beim Verkaufen, damit kein Gold aus Versehen weg
/// ist (07, Grundsatz 4). Auf Stufe 2 mit Angebot derselbe Knopf als
/// Spezialisierung, mit Stern statt Pfeil (P3-1).
private struct UpgradeRingButton: View {
    let cost: Int
    let armed: Bool
    let affordable: Bool
    let specialization: Specialization?
    /// Bei zwei Sternen trägt jeder seinen Namen (`specialize.<name>`, P3-3).
    var identifier: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RingButtonFace(highlighted: armed, tint: specialization == nil ? UITheme.fresh : UITheme.coin,
                           size: BattleStyle.ringButton) {
                VStack(spacing: 0) {
                    if identifier != nil, let specialization {
                        // Zwei Sterne: der Anfangsbuchstabe unterscheidet sie (07).
                        Text("★ \(BattleTexts.initial(specialization))").font(UITheme.display(14))
                    } else {
                        Image(systemName: specialization == nil ? "chevron.up.2" : "star.fill")
                            .font(.system(size: 15, weight: .heavy))
                    }
                    Text(armed ? BattleTexts.levelTag(specialization == nil ? 2 : 3) : "\(cost)").font(UITheme.display(15))
                }
                .foregroundStyle(armed ? UITheme.outline : affordable ? UITheme.cream : UITheme.danger)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(4)
            }
        }
        .buttonStyle(RingPressStyle())
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier ?? (specialization == nil ? "upgrade" : "specialize"))
    }

    private var label: String {
        guard let specialization else {
            return armed ? BattleTexts.confirmUpgrade(cost)
                         : affordable ? BattleTexts.upgradeLine(cost) : "\(BattleTexts.upgrade), \(BattleTexts.notEnoughGold)"
        }
        return armed ? BattleTexts.confirmSpecialize(specialization, cost: cost)
                     : affordable ? "\(BattleTexts.specialize): \(BattleTexts.specializeLine(specialization, cost: cost))"
                                  : "\(BattleTexts.specialize), \(BattleTexts.notEnoughGold)"
    }
}

/// Zielwahl: zeigt die aktuelle Wahl, jedes Tippen schaltet weiter.
private struct TargetRingButton: View {
    let mode: TargetMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RingButtonFace(highlighted: false, tint: UITheme.heart, size: BattleStyle.ringButton) {
                VStack(spacing: 0) {
                    Image(systemName: "scope").font(.system(size: 15, weight: .heavy))
                    Text(BattleTexts.targetMode(mode)).font(UITheme.display(12))
                }
                .foregroundStyle(UITheme.cream)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(4)
            }
        }
        .buttonStyle(RingPressStyle())
        .accessibilityLabel(BattleTexts.targetLine(mode))
        .accessibilityValue(BattleTexts.targetMode(mode))
        .accessibilityIdentifier("target")
    }
}

/// Name, Rolle, Zusammenspiel und was das nächste Tippen tut.
private struct InfoPanel: View {
    let title: String
    let lines: InfoLines
    let action: String
    let actionID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(UITheme.display(19))
                .accessibilityIdentifier("panel.title")
            Text(lines.first).font(UITheme.body(13)).foregroundStyle(UITheme.parchment)
                .accessibilityIdentifier("panel.first")
            Text(lines.second).font(lines.warn ? UITheme.bodyHeavy(13) : UITheme.body(13))
                .foregroundStyle(lines.warn ? UITheme.danger : UITheme.fresh)
                .accessibilityIdentifier("panel.second")
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
        case .bank: UITheme.coin
        }
    }
}
