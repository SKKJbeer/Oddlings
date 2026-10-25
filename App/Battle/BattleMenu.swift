import OddlingsCore
import SwiftUI

/// Bau- und Turmmenü an der gewählten Zelle (WP-12). Liegt über der Szene und
/// rechnet mit demselben `BoardLayout`, damit es genau neben der Zelle sitzt.
/// Steht die Zelle in den oberen Reihen, öffnet es nach unten, sonst nach
/// oben: Der Finger soll die Zelle nicht verdecken, um die es geht.
struct BattleMenu: View {
    let controller: BattleController

    var body: some View {
        GeometryReader { geometry in
            let layout = BoardLayout(size: geometry.size, map: controller.map)
            if let cell = anchorCell {
                content
                    .padding(BattleStyle.menuPadding)
                    .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                    .fixedSize()
                    .modifier(Anchored(point: layout.viewPoint(cell.center), field: layout.field,
                                       opensDown: cell.y < 2, bounds: geometry.size))
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("battle.menu")
            }
        }
    }

    private var anchorCell: Cell? {
        switch controller.selection {
        case .none: nil
        case .cell(let cell, _): cell
        case .tower: controller.selectedTower?.cell
        }
    }

    @ViewBuilder private var content: some View {
        switch controller.selection {
        case .none:
            EmptyView()
        case .cell(_, let choice):
            HStack(spacing: BattleStyle.menuSpacing) {
                ForEach(TowerKind.allCases, id: \.self) { kind in
                    MenuButton(title: choice == kind ? BattleTexts.build : BattleTexts.name(kind),
                               detail: BattleTexts.price(controller.cost(of: kind)),
                               highlighted: choice == kind) {
                        controller.choose(kind)
                    }
                    .disabled(!controller.canAfford(kind))
                    .accessibilityIdentifier("build.\(kind.rawValue)")
                }
            }
        case .tower:
            if let tower = controller.selectedTower {
                HStack(spacing: BattleStyle.menuSpacing) {
                    Text(BattleTexts.name(tower.kind))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, BattleStyle.menuPadding)
                    MenuButton(title: BattleTexts.sell(refund: controller.refund(for: tower)),
                               detail: nil, highlighted: false) {
                        controller.sell()
                    }
                    .accessibilityIdentifier("sell")
                }
            }
        }
    }
}

private struct MenuButton: View {
    let title: String
    let detail: String?
    let highlighted: Bool
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title).font(.subheadline.bold())
                if let detail { Text(detail).font(.caption) }
            }
            .padding(.horizontal, 10)
            .frame(minWidth: BattleStyle.tapTarget * 1.8, minHeight: BattleStyle.tapTarget)
            .foregroundStyle(highlighted ? .black : .white)
            .background(highlighted ? Color.yellow : Color.white.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 8))
            .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
    }
}

/// Setzt das Menü über oder unter den Punkt und hält es im Bildschirm.
private struct Anchored: ViewModifier {
    let point: CGPoint
    let field: CGFloat
    let opensDown: Bool
    let bounds: CGSize
    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .position(position)
    }

    private var position: CGPoint {
        let margin = BattleStyle.screenMargin
        let halfWidth = size.width / 2, halfHeight = size.height / 2
        let x = min(max(point.x, margin + halfWidth), bounds.width - margin - halfWidth)
        let offset = field * 0.6 + halfHeight
        let y = opensDown ? point.y + offset : point.y - offset
        return CGPoint(x: x, y: min(max(y, margin + halfHeight), bounds.height - margin - halfHeight))
    }
}
