import OddlingsCore
import SwiftUI

/// Kopfleiste der Mission (WP-13). Liest nur die Kopien im
/// `BattleController` und gibt Eingaben als dessen Befehle weiter; den
/// Spielzustand fasst sie nie an (Architekturregel 2). Sie liegt über der
/// Karte, nicht darauf, damit kein Knopf eine Bauzelle verdeckt.
struct BattleTopBar: View {
    let controller: BattleController
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: BattleStyle.menuSpacing) {
            HUDButton(title: BattleTexts.back, action: onClose)
                .accessibilityIdentifier("hud.back")
            HStack(spacing: BattleStyle.menuSpacing * 2) {
                Label(BattleTexts.gold(controller.gold), systemImage: "circle.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityIdentifier("hud.gold")
                Label(BattleTexts.lives(controller.lives), systemImage: "heart.fill")
                    .foregroundStyle(.pink)
                    .accessibilityIdentifier("hud.lives")
                Text(BattleTexts.wave(controller.wave, of: controller.waveCount))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("hud.wave")
            }
            .font(.headline.monospacedDigit())
            .padding(.horizontal, BattleStyle.menuPadding * 2)
            .frame(minHeight: BattleStyle.hudHeight)
            .background(.black.opacity(0.55), in: Capsule())
            Spacer()
            if controller.canCallNextWave, let seconds = controller.secondsToNextWave {
                HUDButton(title: BattleTexts.callWave(in: seconds), action: controller.callNextWave)
                    .accessibilityIdentifier("hud.nextWave")
            }
            HUDButton(title: BattleTexts.speed(controller.speed), action: controller.toggleSpeed)
                .accessibilityIdentifier("hud.speed")
            HUDButton(title: controller.paused ? BattleTexts.resume : BattleTexts.pause,
                      action: controller.togglePause)
                .accessibilityIdentifier("hud.pause")
                .disabled(controller.outcome != nil)
        }
    }
}

/// Pausenhinweis und Ergebnistafel (WP-14) über der Karte.
struct BattleOverlay: View {
    let controller: BattleController
    var onRestart: () -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            if controller.paused {
                Text(BattleTexts.paused)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding()
                    .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)
            }
            if let outcome = controller.outcome {
                ResultCard(outcome: outcome, lives: controller.lives,
                           total: controller.model.sim.config.mission.fortressLives,
                           onRestart: onRestart, onClose: onClose)
            }
        }
    }
}

private struct HUDButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, BattleStyle.menuPadding * 2)
                .frame(minWidth: BattleStyle.tapTarget, minHeight: BattleStyle.hudHeight)
                .foregroundStyle(.white)
                .background(.black.opacity(0.55), in: Capsule())
                .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
    }
}

private struct ResultCard: View {
    let outcome: Outcome
    let lives: Int
    let total: Int
    var onRestart: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(outcome == .won ? BattleTexts.won : BattleTexts.lost)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(outcome == .won ? .yellow : .red)
                .accessibilityIdentifier("result.title")
            Text(outcome == .won ? BattleTexts.result(lives: lives, of: total) : BattleTexts.resultLost)
                .font(.headline)
                .foregroundStyle(.white)
            HStack(spacing: BattleStyle.menuSpacing * 2) {
                HUDButton(title: BattleTexts.again, action: onRestart)
                    .accessibilityIdentifier("result.again")
                HUDButton(title: BattleTexts.back, action: onClose)
                    .accessibilityIdentifier("result.back")
            }
        }
        .padding(28)
        .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result")
    }
}
