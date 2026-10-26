import OddlingsCore
import SwiftUI

/// Kopfleiste der Mission (WP-13, Aussehen UI 01). Liest nur die Kopien im
/// `BattleController` und gibt Eingaben als dessen Befehle weiter; den
/// Spielzustand fasst sie nie an (Architekturregel 2). Sie liegt über der
/// Karte, nicht darauf, solange D-030 auf den Spieltest wartet.
struct BattleTopBar: View {
    let controller: BattleController
    var onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: BattleStyle.menuSpacing) {
            RoundBarButton(systemImage: "chevron.left", label: BattleTexts.back, action: onClose)
                .accessibilityIdentifier("hud.back")
            HStack(spacing: 14) {
                counter(symbol: "heart.fill", color: UITheme.heart,
                        value: "\(controller.lives)", label: BattleTexts.lives(controller.lives), id: "hud.lives")
                    .keyframeAnimator(initialValue: CGFloat.zero, trigger: controller.leaks) { content, x in
                        content.offset(x: reduceMotion ? 0 : x)
                    } keyframes: { _ in
                        KeyframeTrack {
                            LinearKeyframe(6, duration: 0.05)
                            LinearKeyframe(-6, duration: 0.1)
                            LinearKeyframe(4, duration: 0.08)
                            LinearKeyframe(-3, duration: 0.07)
                            LinearKeyframe(0, duration: 0.06)
                        }
                    }
                counter(symbol: "circle.hexagongrid.fill", color: UITheme.coin,
                        value: "\(controller.gold)", label: BattleTexts.gold(controller.gold), id: "hud.gold")
                    .phaseAnimator([false, true, false], trigger: controller.goldWarnings) { content, warn in
                        content
                            .foregroundStyle(warn ? UITheme.danger : UITheme.cream)
                            .scaleEffect(warn && !reduceMotion ? 1.12 : 1)
                    } animation: { _ in .easeOut(duration: 0.14) }
                counter(symbol: "flag.fill", color: UITheme.parchment,
                        value: "\(controller.wave)/\(controller.waveCount)",
                        label: BattleTexts.wave(controller.wave, of: controller.waveCount), id: "hud.wave")
            }
            .padding(.horizontal, 16)
            .frame(height: BattleStyle.hudHeight)
            .background(BarBackground())
            Spacer(minLength: 0)
            if controller.canCallNextWave, let seconds = controller.secondsToNextWave {
                WaveButton(next: controller.wave + 1,
                           fraction: Double(seconds) / Double(max(1, controller.countdownTotal)),
                           action: controller.callNextWave)
                    .accessibilityLabel(BattleTexts.callWave(in: seconds))
                    .accessibilityIdentifier("hud.nextWave")
            }
            Button(action: controller.toggleSpeed) {
                Text(BattleTexts.speed(controller.speed))
                    .font(UITheme.display(18))
                    .foregroundStyle(controller.speed > 1 ? UITheme.outline : UITheme.cream)
                    .frame(width: 52, height: BattleStyle.hudHeight)
                    .background(BarBackground(fill: controller.speed > 1 ? UITheme.goldFace : UITheme.wood))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(BattleTexts.speed(controller.speed))
            .accessibilityIdentifier("hud.speed")
            RoundBarButton(systemImage: controller.paused ? "play.fill" : "pause.fill",
                           label: controller.paused ? BattleTexts.resume : BattleTexts.pause,
                           action: controller.togglePause)
                .accessibilityIdentifier("hud.pause")
                .disabled(controller.isFinished)
        }
    }

    private func counter(symbol: String, color: Color, value: String, label: String, id: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(UITheme.display(19))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: value)
                .accessibilityLabel(label)
                .accessibilityIdentifier(id)
        }
        .foregroundStyle(UITheme.cream)
    }
}

/// Holzkapsel der Leiste mit dunkler Kontur.
private struct BarBackground: View {
    var fill: Color = UITheme.wood

    var body: some View {
        ZStack {
            Capsule().fill(UITheme.outline).offset(y: 3)
            Capsule().fill(fill)
            Capsule().strokeBorder(UITheme.outline, lineWidth: UITheme.line)
        }
    }
}

private struct RoundBarButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(UITheme.cream)
                .frame(width: BattleStyle.tapTarget, height: BattleStyle.hudHeight)
                .background(BarBackground())
                .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// „Welle rufen“ mit Ring, der bis zum automatischen Start abläuft (D-009).
private struct WaveButton: View {
    let next: Int
    let fraction: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().stroke(UITheme.outline.opacity(0.35), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: max(0, min(1, fraction)))
                        .stroke(UITheme.outline, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: fraction)
                    Image(systemName: "forward.fill").font(.system(size: 10, weight: .black))
                }
                .frame(width: 26, height: 26)
                Text(BattleTexts.nextWaveShort(next)).font(UITheme.display(17))
            }
            .foregroundStyle(UITheme.outline)
            .padding(.horizontal, 12)
            .frame(height: BattleStyle.hudHeight)
            .background(BarBackground(fill: UITheme.goldFace))
        }
        .buttonStyle(.plain)
    }
}

/// Pause- und Ergebnistafel (WP-14, UI 01) über der Karte. Liegt im
/// Kartenbereich, damit die Kopfleiste bedienbar bleibt.
struct BattleOverlay: View {
    let controller: BattleController
    var onRestart: () -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            if let outcome = controller.shownOutcome {
                UITheme.dim.ignoresSafeArea()
                ResultCard(controller: controller, outcome: outcome, onRestart: onRestart, onClose: onClose)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
            } else if controller.paused {
                UITheme.dim.ignoresSafeArea()
                PauseCard(controller: controller, onRestart: onRestart)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.22), value: controller.paused)
        .animation(.easeOut(duration: 0.22), value: controller.shownOutcome)
    }
}

private struct PauseCard: View {
    let controller: BattleController
    var onRestart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(BattleTexts.paused)
                    .font(UITheme.display(32))
                    .accessibilityIdentifier("hud.paused")
                Spacer()
                Text(BattleTexts.mission).font(UITheme.body(15)).foregroundStyle(UITheme.parchment)
            }
            HStack(spacing: 10) {
                StatTile(title: "Welle", value: Double(controller.wave), text: { "\($0)/\(controller.waveCount)" },
                         countUp: false, id: "pause.wave")
                StatTile(title: "Leben", value: Double(controller.lives), text: { "\($0)" }, countUp: false, id: "pause.lives")
                StatTile(title: "Gold", value: Double(controller.gold), text: { "\($0)" }, countUp: false, id: "pause.gold")
            }
            HStack(spacing: 10) {
                Button(BattleTexts.restart, action: onRestart)
                    .buttonStyle(ChunkyButtonStyle(kind: .wood, height: 48, fontSize: 17))
                    .accessibilityIdentifier("pause.restart")
                Button(BattleTexts.giveUp, action: controller.giveUp)
                    .buttonStyle(ChunkyButtonStyle(kind: .wood, height: 48, fontSize: 17))
                    .accessibilityIdentifier("pause.quit")
                Spacer(minLength: 8)
                Button(BattleTexts.resume, action: controller.togglePause)
                    .buttonStyle(ChunkyButtonStyle(kind: .gold, height: 56, fontSize: 24, minWidth: 150))
                    .accessibilityIdentifier("pause.resume")
            }
        }
        .frame(width: 500)
        .woodPanel(padding: 22)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pause.card")
    }
}

private struct ResultCard: View {
    let controller: BattleController
    let outcome: Outcome
    var onRestart: () -> Void
    var onClose: () -> Void

    var body: some View {
        let won = outcome == .won
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                if won {
                    StatTile(title: BattleTexts.livesLeft, value: Double(controller.lives), text: { "\($0)" }, id: "result.lives")
                    StatTile(title: BattleTexts.duration, value: Double(controller.elapsedSeconds),
                             text: BattleTexts.clock, id: "result.duration")
                    StatTile(title: BattleTexts.towersBuilt, value: Double(controller.towersBuilt), text: { "\($0)" },
                             id: "result.towers")
                } else {
                    StatTile(title: BattleTexts.wavesHeld, value: Double(controller.wavesHeld), text: { "\($0)" },
                             id: "result.waves")
                    StatTile(title: BattleTexts.duration, value: Double(controller.elapsedSeconds),
                             text: BattleTexts.clock, id: "result.duration")
                    StatTile(title: BattleTexts.enemiesDefeated, value: Double(controller.enemiesDefeated),
                             text: { "\($0)" }, id: "result.defeated")
                }
            }
            HStack(spacing: 12) {
                Button(BattleTexts.menu, action: onClose)
                    .buttonStyle(ChunkyButtonStyle(kind: .wood, height: 48, fontSize: 18, minWidth: 120))
                    .accessibilityIdentifier("result.back")
                Spacer(minLength: 8)
                Button(won ? BattleTexts.againWon : BattleTexts.againLost, action: onRestart)
                    .buttonStyle(ChunkyButtonStyle(kind: .gold, height: 56, fontSize: 22, minWidth: 210))
                    .accessibilityIdentifier("result.again")
            }
        }
        .frame(width: 460)
        .padding(.top, 26)
        .woodPanel(padding: 22)
        // Das Band sitzt auf der Oberkante der Tafel, wie im Entwurf.
        .overlay(alignment: .top) {
            Text(won ? BattleTexts.wonBanner : BattleTexts.lostBanner)
                .font(UITheme.display(won ? 34 : 28))
                .foregroundStyle(UITheme.cream)
                .shadow(color: UITheme.outline, radius: 0, x: 0, y: 2)
                .padding(.horizontal, 30)
                .frame(height: 56)
                .background(Banner(color: won ? UITheme.victory : UITheme.defeat))
                .accessibilityLabel(won ? BattleTexts.won : BattleTexts.lost)
                .accessibilityIdentifier("result.title")
                .offset(y: -28)
        }
        .padding(.top, 28)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result")
    }
}

/// Band über der Ergebnistafel; `ui_banner_*` ersetzt es, sobald es da ist.
private struct Banner: View {
    let color: Color

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        ZStack {
            shape.fill(UITheme.outline).offset(y: 4)
            shape.fill(color)
            shape.strokeBorder(UITheme.outline, lineWidth: UITheme.line)
        }
    }
}

/// Kachel mit Wert, der beim Erscheinen hochzählt und exakt auf dem echten
/// Wert endet (07, „Ergebnis“). Vorlesen nennt immer den echten Wert.
private struct StatTile: View {
    let title: String
    let value: Double
    let text: (Int) -> String
    var countUp = true
    let id: String
    @State private var shown: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 2) {
            Text(text(Int((shown ?? value).rounded())))
                .monospacedDigit()
                .font(UITheme.display(26))
                .foregroundStyle(UITheme.coin)
                .accessibilityLabel(text(Int(value.rounded())))
                .accessibilityIdentifier(id)
            Text(title).font(UITheme.body(13)).foregroundStyle(UITheme.parchment)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, minHeight: 66)
        .background(UITheme.outline.opacity(0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .task {
            guard countUp, !reduceMotion else { return }
            let steps = 24
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                shown = value * (1 - (1 - t) * (1 - t) * (1 - t))
                try? await Task.sleep(for: .milliseconds(35))
            }
            // Der letzte Wert ist der echte, nicht eine gerundete Zwischenstufe.
            shown = nil
        }
    }
}
