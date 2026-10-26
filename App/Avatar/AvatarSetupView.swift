import OddlingsCore
import SwiftUI

/// Avatar-Aufbau beim ersten „Spielen“ (R-5, r-5-avatar.md): links die Völker,
/// rechts Porträt, Name und „Los geht's“. Danach ist das Volk gesetzt; einen
/// Weg zurück gibt es hier mit Absicht nicht.
struct AvatarSetupView: View {
    let flow: AppFlow

    @State private var race: Race?
    @State private var portrait: String?
    @State private var name = ""
    /// Hat der Spieler selbst getippt, überschreibt ein Volkswechsel den Namen nicht.
    @State private var typed = false

    private var nameField: Binding<String> {
        Binding(get: { name }, set: { name = $0; typed = true })
    }

    private var ready: Bool { race != nil && Avatar.validName(name) != nil }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(AvatarTexts.title)
                    .font(UITheme.display(32))
                    .foregroundStyle(UITheme.coin)
                    .shadow(color: UITheme.outline, radius: 0, x: 0, y: 3)
                Text(AvatarTexts.intro)
                    .font(UITheme.body(15))
                    .foregroundStyle(UITheme.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    ForEach(Race.allCases, id: \.self) { candidate in
                        RaceCard(race: candidate, chosen: race == candidate) { choose(candidate) }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            details
                .frame(width: 270)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(colors: [CampaignStyle.forestDeep, UITheme.wood], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("setup")
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            label(AvatarTexts.portrait)
            HStack(spacing: 10) {
                ForEach(AvatarPortraits.of(race ?? .dwarves)) { candidate in
                    Button { portrait = candidate.id } label: {
                        PortraitView(portrait: candidate, size: 56, selected: race != nil && portrait == candidate.id)
                    }
                    .buttonStyle(.plain)
                    .disabled(race == nil)
                    .opacity(race == nil ? 0.4 : 1)
                    .accessibilityLabel("\(AvatarTexts.portrait) \(candidate.id)")
                    .accessibilityAddTraits(race != nil && portrait == candidate.id ? .isSelected : [])
                    .accessibilityIdentifier("setup.portrait.\(candidate.id)")
                }
            }
            label(AvatarTexts.name)
            HStack(spacing: 8) {
                TextField(AvatarTexts.name, text: nameField)
                    .font(UITheme.bodyHeavy(18))
                    .foregroundStyle(UITheme.outline)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(UITheme.parchment))
                    .accessibilityIdentifier("setup.name")
                    .onChange(of: name) { _, value in
                        // Länger als erlaubt wird nicht getippt, statt still abgewiesen.
                        if value.count > Avatar.maxNameLength { name = String(value.prefix(Avatar.maxNameLength)) }
                    }
                Button { suggestName(replacing: true) } label: {
                    Image(systemName: "dice.fill").font(.system(size: 20, weight: .bold))
                }
                .buttonStyle(ChunkyButtonStyle(kind: .wood, height: 44, fontSize: 18))
                .disabled(race == nil)
                .accessibilityLabel(AvatarTexts.suggest)
                .accessibilityIdentifier("setup.name.suggest")
            }
            Spacer(minLength: 4)
            Button(action: confirm) {
                Label(AvatarTexts.confirm, systemImage: "checkmark.seal.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .gold, height: 58, fontSize: 24))
            .disabled(!ready)
            .accessibilityIdentifier("setup.confirm")
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(UITheme.bodyHeavy(12))
            .tracking(1.5)
            .foregroundStyle(CampaignStyle.gold)
    }

    private func choose(_ candidate: Race) {
        guard candidate != race else { return }
        race = candidate
        portrait = AvatarPortraits.of(candidate)[0].id
        suggestName(replacing: !typed || name.isEmpty)
    }

    /// Vorschlag aus der Liste des Volks. Zufall ist hier erlaubt: Er berührt
    /// keine Spielregel, nur ein Textfeld.
    private func suggestName(replacing: Bool) {
        guard replacing, let race else { return }
        let options = AvatarTexts.suggestions(race).filter { $0 != name }
        name = options.randomElement() ?? name
        typed = false
    }

    private func confirm() {
        guard let race else { return }
        flow.createAvatar(race: race, name: name, portrait: portrait ?? AvatarPortraits.of(race)[0].id)
    }
}

/// Große Karte je Volk: Zeichen, Name und was das Volk in der Mission tut.
private struct RaceCard: View {
    let race: Race
    let chosen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                PortraitView(portrait: AvatarPortraits.of(race)[0], size: 64, selected: chosen)
                Text(CampaignTexts.race(race))
                    .font(UITheme.display(24))
                    .foregroundStyle(UITheme.cream)
                    .shadow(color: UITheme.outline, radius: 0, x: 0, y: 2)
                Text(CampaignTexts.raceDetail(race))
                    .font(UITheme.body(13))
                    .foregroundStyle(UITheme.parchment)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: UITheme.panelRadius, style: .continuous)
                    .fill(LinearGradient(colors: [UITheme.woodFace, UITheme.wood], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: UITheme.panelRadius, style: .continuous)
                    .stroke(chosen ? UITheme.coin : UITheme.outline, lineWidth: chosen ? 4 : UITheme.line)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(CampaignTexts.race(race)). \(CampaignTexts.raceDetail(race))")
        .accessibilityAddTraits(chosen ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("setup.race.\(race.rawValue)")
    }
}
