import OddlingsCore
import SwiftUI

/// Avatar-Menü (R-6, r-6-avatarrang.md): links der Charakter mit Rang und
/// Fortschritt, rechts seine Abschnitte als Reiter: Talente (R-6) und
/// Ausrüstung (R-7a). Ein weiterer Abschnitt ist ein weiterer Reiter.
struct AvatarScreen: View {
    let flow: AppFlow
    @State private var section: AppFlow.AvatarSection

    init(flow: AppFlow) {
        self.flow = flow
        _section = State(initialValue: flow.avatarSection)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 20) {
                if let avatar = flow.avatar {
                    character(avatar)
                        .frame(width: min(240, geometry.size.width * 0.3))
                    VStack(alignment: .leading, spacing: 8) {
                        tabs
                        switch section {
                        case .talents: talents
                        case .equipment: EquipmentPanel(flow: flow)
                        }
                    }
                    .woodPanel(padding: 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .background(LinearGradient(colors: [UITheme.wood, UITheme.woodRim], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea())
        .statusBarHidden()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("avatar.screen")
    }

    private func character(_ avatar: Avatar) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { flow.closeAvatar() } label: {
                RingButtonFace(highlighted: false, tint: UITheme.woodRim, size: 44) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(UITheme.cream)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AvatarTexts.back)
            .accessibilityIdentifier("avatar.back")
            PortraitView(portrait: AvatarPortraits.resolve(avatar.portrait, race: avatar.race), size: 112)
                .overlay(alignment: .bottomTrailing) { RankMark(rank: flow.rank, size: 44) }
                .frame(maxWidth: .infinity)
            Text(avatar.name)
                .font(UITheme.display(28))
                .foregroundStyle(UITheme.cream)
                .shadow(color: UITheme.outline, radius: 0, x: 0, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
            Text("\(CampaignTexts.race(avatar.race)) · \(AvatarTexts.rank(flow.rank))")
                .font(UITheme.bodyHeavy(15))
                .foregroundStyle(UITheme.coin)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("avatar.rank")
            RankProgress(stars: flow.progress.totalStars, from: flow.rankFloorStars, to: flow.nextRankStars)
            Text(AvatarTexts.progress(stars: flow.progress.totalStars, next: flow.nextRankStars, rank: flow.rank))
                .font(UITheme.body(13))
                .foregroundStyle(UITheme.parchment)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("avatar.progress")
        }
    }

    private var tabs: some View {
        HStack(spacing: 18) {
            tab(AvatarTexts.talents, .talents, id: "avatar.tab.talents")
            tab(AvatarTexts.equipment, .equipment, id: "avatar.tab.equipment")
            Spacer(minLength: 0)
        }
    }

    private func tab(_ title: String, _ target: AppFlow.AvatarSection, id: String) -> some View {
        let active = section == target
        return Button { section = target } label: {
            Text(title)
                .font(UITheme.display(24))
                .foregroundStyle(active ? UITheme.coin : UITheme.parchment.opacity(0.7))
                .shadow(color: UITheme.outline, radius: 0, x: 0, y: 2)
                .padding(.bottom, 2)
                .overlay(alignment: .bottom) {
                    Capsule().fill(active ? UITheme.coin : .clear).frame(height: 3).offset(y: 3)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier(id)
    }

    private var talents: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Spacer(minLength: 8)
                Text(AvatarTexts.switchHint)
                    .font(UITheme.body(12))
                    .foregroundStyle(UITheme.parchment)
                    .multilineTextAlignment(.trailing)
            }
            // Vier Reihen passen auf ein großes Telefon; auf dem kleinsten rollt
            // die Spalte, statt die Karten unlesbar klein zu machen.
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(flow.talentRows.enumerated()), id: \.offset) { index, row in
                        TalentRowView(row: row, index: index, unlocked: index < flow.unlockedTalentRows,
                                      chosen: index < flow.talents.count ? flow.talents[index] : nil) { side in
                            flow.chooseTalent(row: index, side: side)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
}

/// Drei Plätze mit ihren Stücken (R-7a). Noch nicht erhaltene Stücke stehen
/// gesperrt da und sagen, woher sie kommen: Der Spieler weiß, worauf er hinspielt.
private struct EquipmentPanel: View {
    let flow: AppFlow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer(minLength: 8)
                Text(AvatarTexts.equipHint)
                    .font(UITheme.body(12))
                    .foregroundStyle(UITheme.parchment)
                    .multilineTextAlignment(.trailing)
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(AvatarTexts.slot(slot).uppercased()) · \(AvatarTexts.slotRole(slot))")
                                .font(UITheme.bodyHeavy(12))
                                .tracking(1.5)
                                .foregroundStyle(UITheme.coin)
                                .accessibilityIdentifier("equip.slot.\(slot.rawValue)")
                            HStack(spacing: 10) {
                                ForEach(flow.equipment?.pieces(in: slot) ?? [], id: \.id) { piece in
                                    card(piece)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private func card(_ piece: EquipmentPiece) -> some View {
        let owned = flow.owns(piece.id)
        let equipped = flow.isEquipped(piece.id)
        return Button { flow.equip(equipped ? nil : piece.id, in: piece.slot) } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if !owned { Image(systemName: "lock.fill").font(.system(size: 13, weight: .bold)) }
                    Text(AvatarTexts.piece(piece.id))
                        .font(UITheme.display(19))
                }
                .foregroundStyle(UITheme.cream)
                Text(owned ? AvatarTexts.bonus(piece) : AvatarTexts.locked(piece.source))
                    .font(UITheme.body(12))
                    .foregroundStyle(UITheme.parchment)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: UITheme.panelRadius, style: .continuous)
                    .fill(LinearGradient(colors: [UITheme.woodFace, UITheme.wood], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: UITheme.panelRadius, style: .continuous)
                    .stroke(equipped ? UITheme.coin : UITheme.outline, lineWidth: equipped ? 4 : UITheme.line)
            )
            .opacity(owned ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!owned)
        .accessibilityLabel(owned ? "\(AvatarTexts.piece(piece.id)). \(AvatarTexts.bonus(piece))"
                                  : "\(AvatarTexts.piece(piece.id)). \(AvatarTexts.locked(piece.source))")
        .accessibilityAddTraits(equipped ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("equip.\(piece.id)")
    }
}

/// Sternbalken vom Beginn des Rangs bis zum nächsten. Auf dem höchsten Rang voll.
private struct RankProgress: View {
    let stars: Int
    let from: Int
    let to: Int?

    var body: some View {
        let share = to.map { $0 > from ? Double(stars - from) / Double($0 - from) : 1 } ?? 1
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(UITheme.outline.opacity(0.7))
                Capsule().fill(UITheme.goldFace)
                    .frame(width: max(0, min(1, share)) * geometry.size.width)
                Capsule().strokeBorder(UITheme.outline, lineWidth: UITheme.line)
            }
        }
        .frame(height: 14)
        .accessibilityHidden(true)
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
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
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
