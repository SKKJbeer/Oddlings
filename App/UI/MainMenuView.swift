import OddlingsCore
import SwiftUI

/// Hauptmenü (07-ui-ux.md, „Hauptmenü“): Bild links, Knöpfe rechts im
/// Daumenbereich. Kennt keine Navigation; was ein Knopf öffnet, entscheidet
/// der Aufrufer über die Rückrufe.
struct MainMenuView: View {
    /// „Weiter mit Mission N" (07): springt ohne Umweg über die Karte in die
    /// nächste offene Mission. Fehlt, wenn es nichts fortzusetzen gibt.
    var continueTitle: String?
    var continueDetail: String?
    var onContinue: () -> Void = {}
    var onPlay: () -> Void
    var onWatch: () -> Void
    var onSpike: () -> Void
    var onSettings: () -> Void = {}
    /// Avatarschild oben links neben den Einstellungen (R-5); fehlt vor dem Aufbau.
    var avatar: Avatar?
    var rank = 1
    var newTalent = false
    /// Das Schild öffnet die Avatartafel (R-6).
    var onAvatar: () -> Void = {}

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                MenuArt(size: geometry.size)
                LinearGradient(stops: [.init(color: .clear, location: 0.35),
                                       .init(color: UITheme.wood.opacity(0.92), location: 0.62)],
                               startPoint: .leading, endPoint: .trailing)
                HStack(spacing: 0) {
                    VStack(alignment: .leading) {
                        Spacer()
                        Text(BattleTexts.offline)
                            .font(UITheme.body(14))
                            .foregroundStyle(UITheme.cream)
                            .padding(.horizontal, 12)
                            .frame(height: 28)
                            .background(UITheme.outline.opacity(0.6), in: Capsule())
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, 18)
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 12) {
                            Button(action: onSettings) {
                                RingButtonFace(highlighted: false, tint: UITheme.woodRim, size: 48) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(UITheme.cream)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(MenuTexts.settings)
                            .accessibilityIdentifier("menu.settings")
                            if let avatar {
                                Button(action: onAvatar) {
                                    AvatarBadge(avatar: avatar, rank: rank, newTalent: newTalent)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("menu.avatar")
                            }
                        }
                        // Die Spalte darunter ist nur so breit wie „Offline“; das
                        // Schild darf über sie hinausragen, statt umzubrechen.
                        .fixedSize()
                        .padding(.top, 18)
                        .padding(.leading, 24)
                    }
                    Spacer(minLength: 0)
                    buttons
                        .frame(width: min(340, geometry.size.width * 0.4))
                        .padding(.trailing, 28)
                }
            }
        }
        .ignoresSafeArea(edges: .horizontal)
        .background(UITheme.wood)
        .statusBarHidden()
    }

    private var buttons: some View {
        VStack(spacing: 14) {
            Text("Oddlings")
                .font(UITheme.display(54))
                .foregroundStyle(UITheme.coin)
                .shadow(color: UITheme.outline, radius: 0, x: 0, y: 4)
            if let continueTitle {
                Button(action: onContinue) {
                    VStack(spacing: 0) {
                        Text(continueTitle).font(UITheme.display(19))
                        if let continueDetail {
                            Text(continueDetail).font(UITheme.body(13)).foregroundStyle(UITheme.parchment)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(kind: .wood, height: 54, fontSize: 19))
                .accessibilityIdentifier("menu.continue")
            }
            Button(action: onPlay) {
                Label(BattleTexts.play, systemImage: "play.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .gold, height: 64, fontSize: 30))
            .accessibilityIdentifier("menu.play")
            Button(action: onWatch) { Text(BattleTexts.watch).frame(maxWidth: .infinity) }
                .buttonStyle(ChunkyButtonStyle(kind: .wood, height: 48, fontSize: 18))
                .accessibilityIdentifier("menu.watch")
            // Bleibt, bis WP-01 auf dem iPhone gemessen ist.
            Button(action: onSpike) { Text(BattleTexts.spike).frame(maxWidth: .infinity) }
                .buttonStyle(ChunkyButtonStyle(kind: .wood, height: 44, fontSize: 15))
                .accessibilityIdentifier("menu.spike")
        }
    }
}

/// Platzhalter für `ui_keyart_menu`: die gemalte Karte von Mission 1 mit
/// Festung und den drei Türmen davor. Aus den Bildern, die es schon gibt,
/// damit das Menü nicht leer wirkt, bis das Titelbild gemalt ist.
private struct MenuArt: View {
    let size: CGSize

    var body: some View {
        if let keyArt = UITheme.image("ui_keyart_menu") {
            Image(uiImage: keyArt).resizable().scaledToFill().frame(width: size.width, height: size.height).clipped()
        } else {
            ZStack(alignment: .bottomLeading) {
                if let ground = UITheme.image(BattleSprites.groundName(missionID: "mission-01")) {
                    Image(uiImage: ground).resizable().scaledToFill()
                        .frame(width: size.width, height: size.height).clipped()
                        .saturation(0.9)
                        .overlay(UITheme.outline.opacity(0.25))
                } else {
                    LinearGradient(colors: [UITheme.wood, UITheme.woodRim], startPoint: .top, endPoint: .bottom)
                }
                HStack(alignment: .bottom, spacing: -size.height * 0.06) {
                    figure(BattleSprites.fortressName, height: size.height * 0.62)
                    ForEach(TowerKind.allCases, id: \.self) { kind in
                        figure(BattleSprites.towerName(kind), height: size.height * 0.34)
                    }
                }
                .padding(.leading, size.width * 0.04)
                .padding(.bottom, size.height * 0.1)
            }
            .frame(width: size.width, height: size.height)
        }
    }

    @ViewBuilder private func figure(_ name: String, height: CGFloat) -> some View {
        if let picture = UITheme.image(name) {
            Image(uiImage: picture).resizable().scaledToFit().frame(height: height)
                .shadow(color: UITheme.outline.opacity(0.5), radius: 6, x: 0, y: 6)
        }
    }
}
