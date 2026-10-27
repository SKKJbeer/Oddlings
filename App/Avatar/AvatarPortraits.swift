import OddlingsCore
import SwiftUI

/// Porträtkatalog des Avatars (R-5). Die Kennung steht im Spielstand, das Bild
/// heißt `portrait_<kennung>` im Asset-Katalog. Solange der Grafik-Thread die
/// gemalten Brustbilder nicht geliefert hat, zeichnet `PortraitView` das Zeichen
/// des Volks auf drei Farbstellungen; Kennungen und Spielstand bleiben gleich.
struct AvatarPortrait: Identifiable, Equatable {
    let id: String
    let race: Race
    let tint: Color

    var imageName: String { "portrait_\(id)" }
}

enum AvatarPortraits {
    static let all: [AvatarPortrait] = [
        AvatarPortrait(id: "dwarf-1", race: .dwarves, tint: Color(red: 0.62, green: 0.30, blue: 0.16)),
        AvatarPortrait(id: "dwarf-2", race: .dwarves, tint: Color(red: 0.40, green: 0.42, blue: 0.48)),
        AvatarPortrait(id: "dwarf-3", race: .dwarves, tint: Color(red: 0.70, green: 0.52, blue: 0.20)),
        AvatarPortrait(id: "elf-1", race: .elves, tint: Color(red: 0.20, green: 0.48, blue: 0.32)),
        AvatarPortrait(id: "elf-2", race: .elves, tint: Color(red: 0.26, green: 0.36, blue: 0.62)),
        AvatarPortrait(id: "elf-3", race: .elves, tint: Color(red: 0.52, green: 0.30, blue: 0.56)),
    ]

    static func of(_ race: Race) -> [AvatarPortrait] { all.filter { $0.race == race } }

    /// Eine Kennung, die diese App nicht kennt (ältere oder neuere Fassung),
    /// zeigt das erste Porträt des Volks, statt den Avatar zu verwerfen.
    static func resolve(_ id: String, race: Race) -> AvatarPortrait {
        all.first { $0.id == id && $0.race == race } ?? of(race)[0]
    }
}

/// Rundes Porträt: das gemalte Bild, sonst der Platzhalter.
struct PortraitView: View {
    let portrait: AvatarPortrait
    let size: CGFloat
    var selected = false

    var body: some View {
        ZStack {
            if let picture = UITheme.image(portrait.imageName) {
                Image(uiImage: picture).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [portrait.tint.opacity(0.95), portrait.tint.opacity(0.55)],
                               startPoint: .top, endPoint: .bottom)
                Image(systemName: CampaignStyle.raceSymbol(portrait.race))
                    .font(.system(size: size * 0.42, weight: .black))
                    .foregroundStyle(UITheme.cream)
                    .shadow(color: UITheme.outline, radius: 0, x: 0, y: 2)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(selected ? UITheme.coin : UITheme.outline, lineWidth: selected ? 4 : UITheme.line))
    }
}

/// Avatarschild: Porträt, Name, Volk. Hauptmenü und Missionstafel.
struct AvatarBadge: View {
    let avatar: Avatar
    var rank = 1
    var size: CGFloat = 44
    /// Ein neuer Rang hat ein Talent freigegeben, die Tafel war noch nicht offen.
    var newTalent = false

    var body: some View {
        HStack(spacing: 10) {
            PortraitView(portrait: AvatarPortraits.resolve(avatar.portrait, race: avatar.race), size: size)
                .overlay(alignment: .bottomTrailing) { RankMark(rank: rank, size: size * 0.46) }
            VStack(alignment: .leading, spacing: 0) {
                Text(avatar.name)
                    .font(UITheme.display(20))
                    .foregroundStyle(UITheme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(newTalent ? AvatarTexts.newTalent : CampaignTexts.race(avatar.race))
                    .font(UITheme.bodyHeavy(13))
                    .foregroundStyle(newTalent ? UITheme.outline : UITheme.coin)
                    .padding(.horizontal, newTalent ? 6 : 0)
                    .background(Capsule().fill(newTalent ? UITheme.goldFace : .clear))
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 14)
        .padding(.vertical, 4)
        .background(Capsule().fill(UITheme.outline.opacity(0.6)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AvatarTexts.badge(avatar, rank: rank))
        .accessibilityValue(newTalent ? AvatarTexts.newTalent : "")
    }
}

/// Rangabzeichen am Porträt. Bis der Grafik-Thread Abzeichen liefert, eine Münze
/// mit römischer Ziffer.
struct RankMark: View {
    let rank: Int
    let size: CGFloat

    var body: some View {
        Text(AvatarTexts.roman(rank))
            .font(UITheme.display(size * 0.5))
            .foregroundStyle(UITheme.outline)
            .minimumScaleFactor(0.5)
            .frame(width: size, height: size)
            .background(Circle().fill(UITheme.coin))
            .overlay(Circle().stroke(UITheme.outline, lineWidth: 2))
            .offset(x: size * 0.15, y: size * 0.1)
            .accessibilityHidden(true)
    }
}
