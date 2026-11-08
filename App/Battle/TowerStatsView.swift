import OddlingsCore
import SwiftUI

/// Was die Wertetafel zeigt (D-130): die Kennzahlen einer Turmart, beim
/// vorgemerkten Kauf als Vergleich.
struct TowerStatBlock {
    let kind: TowerKind
    let changes: [TowerChange]
    /// Alt → neu zeigen; sonst nur der heutige Wert.
    let comparing: Bool
}

/// Vier Kacheln im Holz der Infotafel. Die erste ist die Leitzahl und trägt
/// einen Goldschimmer; beim Vergleich zeigt jede Kachel alt → neu mit einem
/// Schild (grün: Plus, orange: Preis, braun: gleich) und einen Balken, dessen
/// heller Teil der alte Wert ist.
struct TowerStatGrid: View {
    let block: TowerStatBlock
    /// Zwei in der hohen Tafel, vier in der Leiste.
    var columns = 2

    var body: some View {
        let shown = Array(block.changes.prefix(4))
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: columns), spacing: 5) {
            ForEach(shown.indices, id: \.self) { index in
                StatTile(change: shown[index], kind: block.kind, comparing: block.comparing, lead: index == 0)
            }
        }
    }
}

private struct StatTile: View {
    let change: TowerChange
    let kind: TowerKind
    let comparing: Bool
    let lead: Bool

    var body: some View {
        let figure = change.figure
        let changed = comparing && !change.isUnchanged
        VStack(alignment: .leading, spacing: 1) {
            Text(TowerStatTexts.label(figure, kind: kind).uppercased())
                .font(UITheme.bodyHeavy(8.5))
                .tracking(0.8)
                .foregroundStyle(UITheme.parchment.opacity(0.85))
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                if changed, let before = change.before {
                    Text(TowerStatTexts.value(figure, before))
                        .font(UITheme.display(11))
                        .foregroundStyle(UITheme.parchment.opacity(0.7))
                    Text("→").font(UITheme.bodyHeavy(10)).foregroundStyle(UITheme.parchment.opacity(0.7))
                }
                if let after = change.after {
                    Text(TowerStatTexts.value(figure, after))
                        .font(UITheme.display(changed ? 15 : 16))
                        .foregroundStyle(UITheme.cream)
                }
                if !comparing, let unit = TowerStatTexts.unit(figure) {
                    Text(unit).font(UITheme.bodyHeavy(9)).foregroundStyle(UITheme.parchment)
                }
                Spacer(minLength: 0)
                if comparing, let delta = TowerStatTexts.delta(change) {
                    DeltaChip(text: delta, tone: tone)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            if changed { growthBar }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 9)
            .fill(lead ? UITheme.coin.opacity(0.13) : Color.black.opacity(0.22)))
        .overlay(RoundedRectangle(cornerRadius: 9)
            .strokeBorder(lead ? UITheme.coin.opacity(0.35) : Color.black.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TowerStatTexts.spoken(change, kind: kind, comparing: comparing))
        .accessibilityValue(comparing ? (TowerStatTexts.delta(change) ?? "") : "")
        .accessibilityIdentifier("stat.\(change.figure.rawValue)")
    }

    private var tone: DeltaChip.Tone {
        if change.isUnchanged { return .same }
        return (change.difference ?? 0) < 0 ? .cost : .gain
    }

    /// Nur bei einem Plus: Der Balken wächst vom alten zum neuen Wert.
    @ViewBuilder private var growthBar: some View {
        if let before = change.before, let after = change.after, after > before, after > 0, before >= 0 {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.4))
                    Capsule().fill(UITheme.fresh)
                    Capsule().fill(UITheme.parchment).frame(width: geometry.size.width * before / after)
                }
            }
            .frame(height: 3)
        }
    }
}

private struct DeltaChip: View {
    enum Tone { case gain, cost, same }
    let text: String
    let tone: Tone

    var body: some View {
        Text(text)
            .font(UITheme.bodyHeavy(9.5))
            .foregroundStyle(tone == .same ? UITheme.parchment : UITheme.outline)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 5).fill(fill))
            .fixedSize()
    }

    private var fill: Color {
        switch tone {
        case .gain: UITheme.fresh
        case .cost: UITheme.danger
        case .same: UITheme.woodRim
        }
    }
}
