import OddlingsCore
import SwiftUI

/// Avatartafel (R-6, r-6-avatarrang.md): Rang, Fortschritt und Talentwahl.
/// Öffnet sich über das Avatarschild im Hauptmenü und auf der Karte.
struct AvatarPanel: View {
    let flow: AppFlow
    var onClose: () -> Void

    var body: some View {
        ZStack {
            UITheme.dim.ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)
            if let avatar = flow.avatar {
                VStack(alignment: .leading, spacing: 12) {
                    header(avatar)
                    ForEach(Array(flow.talentRows.enumerated()), id: \.offset) { index, row in
                        TalentRowView(row: row, index: index, unlocked: index < flow.unlockedTalentRows,
                                      chosen: index < flow.talents.count ? flow.talents[index] : nil) { side in
                            flow.chooseTalent(row: index, side: side)
                        }
                    }
                    HStack(alignment: .center, spacing: 12) {
                        Text(AvatarTexts.switchHint)
                            .font(UITheme.body(13))
                            .foregroundStyle(UITheme.parchment)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(action: onClose) { Text(AvatarTexts.done).frame(width: 120) }
                            .buttonStyle(ChunkyButtonStyle(kind: .gold, height: 48, fontSize: 20))
                            .accessibilityIdentifier("avatar.panel.done")
                    }
                }
                .frame(width: 560)
                .woodPanel(padding: 18)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("avatar.panel")
            }
        }
    }

    private func header(_ avatar: Avatar) -> some View {
        HStack(spacing: 14) {
            PortraitView(portrait: AvatarPortraits.resolve(avatar.portrait, race: avatar.race), size: 56)
                .overlay(alignment: .bottomTrailing) { RankMark(rank: flow.rank, size: 26) }
            VStack(alignment: .leading, spacing: 2) {
                Text(avatar.name)
                    .font(UITheme.display(26))
                    .foregroundStyle(UITheme.cream)
                    .shadow(color: UITheme.outline, radius: 0, x: 0, y: 2)
                Text("\(CampaignTexts.race(avatar.race)) · \(AvatarTexts.rank(flow.rank))")
                    .font(UITheme.bodyHeavy(15))
                    .foregroundStyle(UITheme.coin)
                    .accessibilityIdentifier("avatar.rank")
            }
            Spacer(minLength: 8)
            Text(AvatarTexts.progress(stars: flow.progress.totalStars, next: flow.nextRankStars, rank: flow.rank))
                .font(UITheme.body(14))
                .foregroundStyle(UITheme.parchment)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("avatar.progress")
        }
    }
}

private struct TalentRowView: View {
    let row: TalentRow
    let index: Int
    let unlocked: Bool
    let chosen: TalentSide?
    let choose: (TalentSide) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(AvatarTexts.row(row.id).uppercased())
                    .font(UITheme.bodyHeavy(12))
                    .tracking(1.5)
                    .foregroundStyle(UITheme.coin)
                if !unlocked {
                    Label(AvatarTexts.locked(rank: index + 2), systemImage: "lock.fill")
                        .font(UITheme.bodyHeavy(12))
                        .foregroundStyle(UITheme.parchment)
                        .accessibilityIdentifier("talent.\(index).locked")
                }
            }
            HStack(spacing: 10) {
                ForEach(TalentSide.allCases, id: \.self) { side in
                    card(side)
                }
            }
        }
        .opacity(unlocked ? 1 : 0.55)
    }

    private func card(_ side: TalentSide) -> some View {
        let option = row[side]
        let selected = unlocked && chosen == side
        return Button { choose(side) } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(AvatarTexts.option(option.id))
                    .font(UITheme.display(19))
                    .foregroundStyle(UITheme.cream)
                Text(AvatarTexts.effect(option))
                    .font(UITheme.body(12))
                    .foregroundStyle(UITheme.parchment)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: UITheme.panelRadius, style: .continuous)
                    .fill(LinearGradient(colors: [UITheme.woodFace, UITheme.wood], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: UITheme.panelRadius, style: .continuous)
                    .stroke(selected ? UITheme.coin : UITheme.outline, lineWidth: selected ? 4 : UITheme.line)
            )
        }
        .buttonStyle(.plain)
        // Der Knopf selbst bleibt das Bedienelement: Ein eigenes
        // `accessibilityElement` darüber verlöre, dass er gesperrt ist.
        .disabled(!unlocked)
        .accessibilityLabel("\(AvatarTexts.option(option.id)). \(AvatarTexts.effect(option))")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("talent.\(index).\(side.rawValue)")
    }
}
