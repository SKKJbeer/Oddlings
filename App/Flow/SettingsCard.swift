import SwiftUI

/// Einstellungen als Tafel über dem Menü (07, „Hauptmenü"). Schreibt
/// `AppSettings` und reicht die Lautstärke sofort an den Ton; der Spielstand
/// bleibt unberührt. Drei Zeilen à 44 pt, damit die Tafel im Querformat auch
/// auf dem kleinsten iPhone ganz zu sehen ist.
struct SettingsCard: View {
    var onClose: () -> Void
    @State private var vibration = AppSettings.vibration()
    @State private var sound = AppSettings.soundVolume()
    @State private var music = AppSettings.musicVolume()

    var body: some View {
        ZStack {
            UITheme.dim.ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
                Text(MenuTexts.settings)
                    .font(UITheme.display(30))
                    .shadow(color: UITheme.outline, radius: 0, x: 0, y: 3)
                VolumeRow(title: MenuTexts.sound, symbol: "speaker.wave.2.fill", value: $sound, id: "settings.sound") {
                    AppSettings.setSoundVolume(sound)
                    AudioDirector.shared.setSoundVolume(sound)
                } onRelease: {
                    AudioDirector.shared.preview()
                }
                VolumeRow(title: MenuTexts.music, symbol: "music.note", value: $music, id: "settings.music") {
                    AppSettings.setMusicVolume(music)
                    AudioDirector.shared.setMusicVolume(music)
                } onRelease: {}
                Toggle(isOn: $vibration) {
                    Label(MenuTexts.vibration, systemImage: "iphone.radiowaves.left.and.right")
                        .font(UITheme.bodyHeavy(18))
                }
                .tint(UITheme.goldFace)
                .frame(minHeight: 44)
                .accessibilityIdentifier("settings.vibration")
                .onChange(of: vibration) { _, on in AppSettings.setVibration(on) }
                Text(MenuTexts.offline)
                    .font(UITheme.body(14))
                    .foregroundStyle(UITheme.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onClose) { Text(MenuTexts.done).frame(maxWidth: .infinity) }
                    .buttonStyle(ChunkyButtonStyle(kind: .gold, height: 52, fontSize: 22))
                    .accessibilityIdentifier("settings.done")
            }
            .frame(width: 440)
            .woodPanel(padding: 22)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("settings")
        }
    }
}

/// Ein Lautstärkeregler mit Wert in Prozent. Wirkt sofort; beim Loslassen
/// spielt der Klangregler einen Probeton (Konzept p2-3, Bedienung).
private struct VolumeRow: View {
    let title: String
    let symbol: String
    @Binding var value: Double
    let id: String
    var onChange: () -> Void
    var onRelease: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label(title, systemImage: symbol)
                .font(UITheme.bodyHeavy(18))
                .frame(width: 120, alignment: .leading)
            Slider(value: $value, in: 0...1) { editing in
                if !editing { onRelease() }
            }
            .tint(UITheme.goldFace)
            .accessibilityLabel(title)
            .accessibilityValue(MenuTexts.percent(value))
            .accessibilityIdentifier(id)
            .onChange(of: value) { _, _ in onChange() }
            Text(MenuTexts.percent(value))
                .font(UITheme.body(16))
                .monospacedDigit()
                .frame(width: 52, alignment: .trailing)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 44)
    }
}
