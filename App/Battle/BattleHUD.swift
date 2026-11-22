import OddlingsCore
import SwiftUI

/// Kopfleiste der Mission (WP-13, als Schilder seit A-5 Teil 2, D-180). Liest
/// nur die Kopien im `BattleController` und gibt Eingaben als dessen Befehle
/// weiter; den Spielzustand fasst sie nie an (Architekturregel 2).
///
/// Kein Band mehr: Jeder Wert ist ein eigenes Holzschild aus dem Material der
/// Tafeln, das über dem gemalten Rand der Karte schwebt (`BattleStyle.boardTop`).
struct BattleTopBar: View {
    let controller: BattleController
    var onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: BattleStyle.plaqueSpacing) {
            RoundPlaqueButton(label: BattleTexts.back, action: onClose) {
                HudIcon(name: nil, fallback: "chevron.left", tint: UITheme.cream, side: 17)
            }
            .accessibilityIdentifier("hud.back")
            ValuePlaque(icon: "ui_icon_heart", fallback: "heart.fill", tint: UITheme.heart) {
                counterText("\(controller.lives)", label: BattleTexts.lives(controller.lives), id: "hud.lives")
            }
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
            ValuePlaque(icon: "ui_icon_gold", fallback: "circle.hexagongrid.fill", tint: UITheme.coin) {
                counterText("\(controller.gold)", label: BattleTexts.gold(controller.gold), id: "hud.gold")
                    .phaseAnimator([false, true, false], trigger: controller.goldWarnings) { content, warn in
                        content
                            .foregroundStyle(warn ? UITheme.danger : UITheme.cream)
                            .scaleEffect(warn && !reduceMotion ? 1.12 : 1)
                    } animation: { _ in .easeOut(duration: 0.14) }
            }
            .overlay(alignment: .bottomTrailing) { BonusFloat(controller: controller) }
            ValuePlaque(icon: "ui_icon_wave", fallback: "flag.fill", tint: UITheme.parchment) {
                counterText("\(controller.wave)/\(controller.waveCount)",
                            label: BattleTexts.wave(controller.wave, of: controller.waveCount), id: "hud.wave")
            }
            Spacer(minLength: 0)
            if controller.canCallNextWave, let seconds = controller.secondsToNextWave {
                WaveButton(next: controller.wave + 1,
                           fraction: Double(seconds) / Double(max(1, controller.countdownTotal)),
                           bonus: controller.callBonus,
                           action: controller.callNextWave)
                    // Einstieg (P2-8): Pfeil darunter, fängt kein Tippen ab.
                    .overlay {
                        if controller.guide.shown == .wave { GuideArrow() }
                    }
                    .accessibilityLabel(BattleTexts.callWave(in: seconds, bonus: controller.callBonus))
                    .accessibilityHint(controller.guide.shown == .wave ? BattleTexts.guideWave : "")
                    .accessibilityIdentifier("hud.nextWave")
            }
            Button(action: controller.toggleSpeed) {
                Text(BattleTexts.speed(controller.speed))
                    .font(UITheme.display(18))
                    .foregroundStyle(controller.speed > 1 ? UITheme.outline : UITheme.cream)
                    .frame(width: BattleStyle.speedButtonWidth, height: BattleStyle.plaqueHeight)
                    .background(HudPlaque(gold: controller.speed > 1))
                    .frame(height: BattleStyle.hudHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlaquePressStyle())
            .accessibilityLabel(BattleTexts.speed(controller.speed))
            .accessibilityIdentifier("hud.speed")
            RoundPlaqueButton(label: controller.paused ? BattleTexts.resume : BattleTexts.pause,
                              action: controller.togglePause) {
                if controller.paused {
                    HudIcon(name: nil, fallback: "play.fill", tint: UITheme.cream, side: 17)
                } else {
                    HudIcon(name: "ui_icon_pause", fallback: "pause.fill", tint: UITheme.cream, side: 22)
                }
            }
            .accessibilityIdentifier("hud.pause")
            .disabled(controller.isFinished)
        }
        .frame(height: BattleStyle.hudHeight)
    }

    private func counterText(_ value: String, label: String, id: String) -> some View {
        Text(value)
            .font(UITheme.display(19))
            .monospacedDigit()
            .foregroundStyle(UITheme.cream)
            .shadow(color: UITheme.outline, radius: 0, x: 0, y: 1.5)
            .contentTransition(.numericText())
            .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: value)
            .accessibilityLabel(label)
            .accessibilityIdentifier(id)
    }
}

/// Holzschild der Kopfleiste (D-180): dieselbe Haut wie Tafeln und Kreismenü
/// (`WoodBackground`, `RingButtonFace`), dazu ein weicher Schatten auf die
/// Karte, damit es über ihr schwebt statt auf ihr klebt. Gold für die Handlung,
/// die gerade zählt (Welle rufen, 2×). Ein gemaltes `ui_plaque` ersetzt die Form später.
struct HudPlaque: View {
    var gold = false
    var round = false

    var body: some View {
        Group {
            if round {
                skin(Circle())
            } else {
                skin(RoundedRectangle(cornerRadius: BattleStyle.plaqueRadius, style: .continuous))
            }
        }
        .compositingGroup()
        .shadow(color: .black.opacity(BattleStyle.plaqueShadowOpacity), radius: BattleStyle.plaqueShadowRadius, x: 0, y: 3)
    }

    private func skin<S: InsettableShape>(_ shape: S) -> some View {
        let face = LinearGradient(colors: gold ? [UITheme.goldFace, UITheme.goldShade] : [UITheme.woodFace, UITheme.wood],
                                  startPoint: .top, endPoint: .bottom)
        return ZStack {
            shape.fill(UITheme.outline).offset(y: 3)
            shape.fill(face)
            shape.inset(by: UITheme.line).strokeBorder(gold ? UITheme.cream.opacity(0.55) : UITheme.woodRim, lineWidth: 2)
            shape.strokeBorder(UITheme.outline, lineWidth: UITheme.line)
        }
    }
}

/// Gemaltes Symbol aus dem Katalog; fehlt es, das SF-Symbol von vorher.
private struct HudIcon: View {
    let name: String?
    let fallback: String
    let tint: Color
    var side: CGFloat = BattleStyle.plaqueIcon

    var body: some View {
        if let name, let picture = UITheme.image(name) {
            Image(uiImage: picture)
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
                .shadow(color: UITheme.outline.opacity(0.6), radius: 1.5, x: 0, y: 1.5)
                .accessibilityHidden(true)
        } else {
            Image(systemName: fallback)
                .font(.system(size: name == nil ? side : side * 0.45, weight: .black))
                .foregroundStyle(tint)
                .frame(width: side, height: side)
                .accessibilityHidden(true)
        }
    }
}

/// Wertschild: Das gemalte Symbol liegt größer als das Schild auf dessen
/// linkem Ende, wie ein aufgelegtes Siegel.
private struct ValuePlaque<Value: View>: View {
    let icon: String
    let fallback: String
    let tint: Color
    @ViewBuilder var value: Value

    var body: some View {
        let lap = BattleStyle.plaqueIcon * 0.3
        HStack(spacing: 4) {
            Color.clear.frame(width: BattleStyle.plaqueIcon - lap)
            value
        }
        .padding(.trailing, 12)
        .frame(height: BattleStyle.plaqueHeight)
        .background(HudPlaque())
        .overlay(alignment: .leading) {
            HudIcon(name: icon, fallback: fallback, tint: tint).offset(x: -lap)
        }
        .padding(.leading, lap)
        .frame(height: BattleStyle.hudHeight)
    }
}

/// Runder Knopf der Kopfleiste. Das Schild ist so hoch wie die Leiste, die
/// Tippfläche so breit wie ein Tippziel (`BattleStyle.tapTarget`).
private struct RoundPlaqueButton<Face: View>: View {
    let label: String
    let action: () -> Void
    @ViewBuilder var face: Face
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            ZStack {
                HudPlaque(round: true).frame(width: BattleStyle.hudHeight, height: BattleStyle.hudHeight)
                face
            }
            .frame(width: BattleStyle.tapTarget, height: BattleStyle.hudHeight)
            .opacity(isEnabled ? 1 : 0.45)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlaquePressStyle())
        .accessibilityLabel(label)
    }
}

/// Gedrückt sinkt ein Schild auf seinen Schatten, wie die Knöpfe der Tafeln.
private struct PlaquePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.offset(y: configuration.isPressed ? 2 : 0)
    }
}

/// Lebensleiste des Bosses oben über der Karte (P3-4), statt über seinem Kopf:
/// So bleibt sie im Getümmel lesbar. Der Strich zeigt, wo der Schild steigt.
struct BossBar: View {
    let status: BossStatus

    var body: some View {
        VStack(spacing: 3) {
            Text(BattleTexts.bossName)
                .font(UITheme.display(15))
                .foregroundStyle(UITheme.cream)
            GeometryReader { box in
                ZStack(alignment: .leading) {
                    Capsule().fill(UITheme.outline)
                    Capsule()
                        .fill(status.shielded ? Color(uiColor: FxStyle.shieldColor) : UITheme.heart)
                        .frame(width: box.size.width * status.fraction)
                    Rectangle()
                        .fill(UITheme.cream)
                        .frame(width: 2)
                        .offset(x: box.size.width * status.shieldAt - 1)
                    Capsule().strokeBorder(UITheme.outline, lineWidth: UITheme.line)
                }
            }
            .frame(width: BattleStyle.bossBarWidth, height: BattleStyle.bossBarHeight)
        }
        .padding(.top, BattleStyle.hudMargin)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BattleTexts.bossName)
        .accessibilityValue(BattleTexts.bossHealth(percent: status.percent, shielded: status.shielded))
        .accessibilityIdentifier("hud.boss")
    }
}

/// „+7“ steigt an der Goldanzeige auf, wenn frühes Rufen Gold gebracht hat.
private struct BonusFloat: View {
    let controller: BattleController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(BattleTexts.gain(controller.lastBonus))
            .font(UITheme.display(15))
            .foregroundStyle(UITheme.coin)
            .keyframeAnimator(initialValue: CGFloat.zero, trigger: controller.bonusGains) { content, t in
                content
                    .opacity(controller.bonusGains == 0 ? 0 : Double(t > 0.7 ? (1 - t) / 0.3 : min(1, t * 6)))
                    .offset(y: reduceMotion ? 18 : 18 - 22 * t)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0, duration: 0.001)
                    LinearKeyframe(1, duration: 1.1)
                    LinearKeyframe(0, duration: 0.001)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// „Welle rufen“ als goldenes Schild mit dem gemalten Horn und einem Ring,
/// der bis zum automatischen Start abläuft (D-009, D-180).
private struct WaveButton: View {
    let next: Int
    let fraction: Double
    /// Gold fürs frühe Rufen (P2-5); 0 in Missionen ohne Bonus.
    var bonus = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                ZStack {
                    Circle().fill(UITheme.outline.opacity(0.25))
                    Circle()
                        .trim(from: 0, to: max(0, min(1, fraction)))
                        .stroke(UITheme.outline, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: fraction)
                    HudIcon(name: "ui_icon_next_wave", fallback: "forward.fill", tint: UITheme.outline, side: 22)
                }
                .frame(width: 28, height: 28)
                Text(BattleTexts.nextWaveShort(next)).font(UITheme.display(17))
                if bonus > 0 {
                    Text(BattleTexts.gain(bonus))
                        .font(UITheme.display(14))
                        .monospacedDigit()
                        .foregroundStyle(UITheme.cream)
                        .padding(.horizontal, 6)
                        .background(Capsule().fill(UITheme.outline))
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(UITheme.outline)
            .padding(.leading, 5)
            .padding(.trailing, 12)
            .frame(height: BattleStyle.plaqueHeight)
            .background(HudPlaque(gold: true))
            .frame(height: BattleStyle.hudHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlaquePressStyle())
    }
}

/// Pfeil des Einstiegs unter „Welle 1“ (P2-8): wippt nach oben zum Knopf, der
/// Knopf glüht. Ohne Berührung und für VoiceOver unsichtbar; den Hinweis trägt
/// der Knopf selbst.
private struct GuideArrow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var up = false

    var body: some View {
        ZStack {
            Capsule()
                .stroke(UITheme.cream, lineWidth: 3)
                .shadow(color: UITheme.goldFace, radius: up ? 10 : 4)
                .padding(-4)
            Image(systemName: "arrowshape.up.fill")
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(UITheme.cream)
                .shadow(color: UITheme.outline, radius: 0, x: 0, y: 2)
                .shadow(color: UITheme.outline.opacity(0.8), radius: 1)
                .offset(y: BattleStyle.hudHeight / 2 + 22 + (up && !reduceMotion ? -6 : 0))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .transition(.opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { up = true }
        }
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
            if let notice = controller.notice {
                Text(notice)
                    .font(UITheme.body(16))
                    .foregroundStyle(UITheme.cream)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("pause.notice")
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
            if let reward = controller.reward {
                Label(reward, systemImage: "hammer.fill")
                    .font(UITheme.bodyHeavy(17))
                    .foregroundStyle(UITheme.coin)
                    // Sonst liest VoiceOver das Hammerbild als „Kompilieren“ vor.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(reward)
                    .accessibilityIdentifier("result.reward")
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

/// Zettel unter „Welle n“ (A-2, D-159): wer kommt und wie viele, neue Arten
/// mit rotem Ausrufezeichen. Fängt kein Tippen ab; die Karte darunter bleibt
/// bedienbar. Breite fest aus `BattleStyle.forecastWidth`, damit Tafel und
/// Bogen genau dieses Rechteck meiden (`HudLayout.forecastRect`).
struct WaveForecastTag: View {
    let forecast: WaveForecast

    var body: some View {
        HStack(spacing: BattleStyle.forecastSpacing) {
            ForEach(forecast.entries, id: \.kind) { entry in
                HStack(spacing: 2) {
                    EnemyPicture(kind: entry.kind)
                        .frame(width: BattleStyle.forecastIcon, height: BattleStyle.forecastIcon)
                        .overlay(alignment: .topTrailing) {
                            if entry.isNew {
                                Text("!")
                                    .font(UITheme.display(11))
                                    .foregroundStyle(UITheme.cream)
                                    .frame(width: 13, height: 13)
                                    .background(Circle().fill(UITheme.heart))
                                    .overlay(Circle().strokeBorder(UITheme.outline, lineWidth: 1.5))
                                    .offset(x: 4, y: -3)
                            }
                        }
                    Text("\(entry.count)")
                        .font(UITheme.display(15))
                        .monospacedDigit()
                        .foregroundStyle(UITheme.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: BattleStyle.forecastEntry, alignment: .leading)
            }
        }
        .padding(.horizontal, BattleStyle.forecastPadding)
        .frame(width: BattleStyle.forecastWidth(entries: forecast.entries.count),
               height: BattleStyle.forecastHeight)
        .background(HudPlaque())
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BattleTexts.forecast(forecast))
        .accessibilityIdentifier("hud.forecast")
    }
}

/// Gegnerbild aus dem Atlas; fehlt es, ein Punkt in der Farbe der Art.
private struct EnemyPicture: View {
    let kind: EnemyKind

    var body: some View {
        if let picture = UITheme.image(BattleSprites.enemyName(kind)) {
            Image(uiImage: picture).resizable().scaledToFit()
        } else {
            Circle().fill(Color(uiColor: BattleStyle.enemyColor(kind))).padding(4)
        }
    }
}
