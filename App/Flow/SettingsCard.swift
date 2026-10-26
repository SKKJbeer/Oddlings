import SwiftUI

/// Einstellungen als Tafel über dem Menü (07, „Hauptmenü"). Liest und schreibt
/// nur `AppSettings`; der Spielstand bleibt unberührt.
struct SettingsCard: View {
    var onClose: () -> Void
    @State private var vibration = AppSettings.vibration()

    var body: some View {
        ZStack {
            UITheme.dim.ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 16) {
                Text(MenuTexts.settings)
                    .font(UITheme.display(30))
                    .shadow(color: UITheme.outline, radius: 0, x: 0, y: 3)
                Toggle(isOn: $vibration) {
                    Label(MenuTexts.vibration, systemImage: "iphone.radiowaves.left.and.right")
                        .font(UITheme.bodyHeavy(18))
                }
                .tint(UITheme.goldFace)
                .frame(minHeight: 44)
                .accessibilityIdentifier("settings.vibration")
                .onChange(of: vibration) { _, on in AppSettings.setVibration(on) }
                Text(MenuTexts.soundLater)
                    .font(UITheme.body(14))
                    .foregroundStyle(UITheme.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onClose) { Text(MenuTexts.done).frame(maxWidth: .infinity) }
                    .buttonStyle(ChunkyButtonStyle(kind: .gold, height: 52, fontSize: 22))
                    .accessibilityIdentifier("settings.done")
            }
            .frame(width: 340)
            .woodPanel(padding: 22)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("settings")
        }
    }
}
