import Observation
import OddlingsCore
import SwiftUI

/// Was der Einstieg schon gezeigt hat, je Gerät (P2-8). Eine Geräteeinstellung
/// wie Ton und Vibration (K6): Es ist Wissen des Spielers an diesem Gerät, kein
/// Fortschritt, und der Spielstand bleibt unberührt.
struct GuideMemory {
    enum Step: String, CaseIterable {
        /// Hand auf eine gute Bauzelle.
        case build
        /// Pfeil auf „Nächste Welle“.
        case wave
        /// Satz unter dem ersten Sporenfunken.
        case spark
    }

    var defaults: UserDefaults = .standard

    static func key(_ step: Step) -> String { "guide.seen.\(step.rawValue)" }

    /// Was in den Voreinstellungen steht, kommt von außen: Nur ein echtes `true`
    /// heißt „gezeigt“, alles andere „noch nicht“. `as? Bool` reicht nicht, es
    /// liest auch die Zahl 1 als wahr.
    func seen(_ step: Step) -> Bool {
        guard let value = defaults.object(forKey: Self.key(step)) as? NSNumber,
              CFGetTypeID(value) == CFBooleanGetTypeID() else { return false }
        return value.boolValue
    }

    func markSeen(_ step: Step) { defaults.set(true, forKey: Self.key(step)) }

    /// Schalter in den Einstellungen.
    var enabled: Bool { AppSettings.guide(in: defaults) }

    /// Für Oberflächentests (`--e2e-frisch`): alles wie bei einer neuen App.
    func reset() {
        for step in Step.allCases { defaults.removeObject(forKey: Self.key(step)) }
        defaults.removeObject(forKey: AppSettings.guideKey)
    }
}

/// Die stillen Zeichen des Einstiegs (P2-8, K8): Mission 1 erklärt nicht, sie
/// zeigt. Ein Zeichen erscheint nur, wenn der Spieler zögert, steht allein,
/// fängt kein Tippen ab und kommt nach dem ersten Mal nie wieder.
///
/// Liest nur, was der `BattleController` ihm reicht, und schreibt nur in
/// `GuideMemory`; den Spielzustand fasst es nie an (Architekturregel 2).
@Observable
@MainActor
final class BattleGuide {
    /// Was gerade zu sehen ist. Höchstens eins zur Zeit.
    enum Shown: Equatable {
        case none
        case build(Cell)
        case wave

        /// Für den Debug-Zähler der End-zu-End-Tests (`guide.state`).
        var name: String {
            switch self {
            case .none: "none"
            case .build: "build"
            case .wave: "wave"
            }
        }
    }

    /// Ein Zeichen in dieser Mission: wartet (mit gezögerten Sekunden), steht, oder ist erledigt.
    private enum Phase: Equatable {
        case waiting(Double)
        case showing
        case done
    }

    /// Was der Controller je Bild weiß. Ein Wert, damit Tests ihn ohne Simulation bauen.
    struct Situation {
        var dt: Double
        var towers: Int
        /// Die erste Welle läuft (gerufen oder von selbst gekommen).
        var firstWaveStarted: Bool
        var canCallWave: Bool
        /// Pause, Zielen, Ergebnistafel: Dann ruht alles, auch das Warten.
        var halted: Bool
    }

    private(set) var shown: Shown = .none
    @ObservationIgnored private let memory: GuideMemory
    @ObservationIgnored private let interactive: Bool
    @ObservationIgnored private var build: Phase
    @ObservationIgnored private var wave: Phase
    @ObservationIgnored private var cell: Cell?
    @ObservationIgnored private let findCell: () -> Cell?
    @ObservationIgnored private var playerCalled = false

    /// `intro`: Diese Mission hat die Einstiegszeichen (erste Mission, noch nicht
    /// gewonnen). `findCell` sucht die Zelle für die Hand, erst wenn sie gebraucht wird.
    init(memory: GuideMemory = GuideMemory(), intro: Bool, interactive: Bool, findCell: @escaping () -> Cell? = { nil }) {
        self.memory = memory
        self.interactive = interactive
        self.findCell = findCell
        let on = intro && interactive && memory.enabled
        build = on && !memory.seen(.build) ? .waiting(0) : .done
        wave = on && !memory.seen(.wave) ? .waiting(0) : .done
    }

    /// Ein Bild weiter.
    func update(_ now: Situation) {
        advanceBuild(now)
        // Einer zur Zeit: Der Pfeil wartet, bis die Hand ihre Sache erledigt hat.
        if build == .done { advanceWave(now) }
        let next: Shown = if now.halted {
            .none
        } else if build == .showing, let cell {
            .build(cell)
        } else if wave == .showing {
            .wave
        } else {
            .none
        }
        // Nur bei Änderung: SwiftUI zeichnet sonst 60-mal je Sekunde neu.
        if shown != next { shown = next }
    }

    /// Der Spieler hat die Welle selbst gerufen: Er weiß, wo der Knopf ist.
    func playerCalledWave() { playerCalled = true }

    /// Jedes Tippen auf die Karte überspringt, was gerade steht. Das Tippen tut
    /// zugleich, was es sonst täte; gesehen war das Zeichen schon.
    func skip() {
        if build == .showing { build = .done }
        if wave == .showing { wave = .done }
        if shown != .none { shown = .none }
    }

    /// Satz unter dem ersten Sporenfunken. Nur einmal je Gerät und nur im
    /// eigenen Spiel; gilt in jeder Mission, weil die Synergie überall dieselbe ist.
    func takeSparkSentence() -> Bool {
        guard interactive, memory.enabled, !memory.seen(.spark) else { return false }
        memory.markSeen(.spark)
        return true
    }

    private func advanceBuild(_ now: Situation) {
        switch build {
        case .waiting(let seconds):
            // Wer baut, bevor die Hand kommt, braucht sie nicht.
            if now.towers > 0 {
                build = .done
                memory.markSeen(.build)
            } else if !now.halted {
                let waited = seconds + now.dt
                if waited >= BattleStyle.guideBuildDelay, let found = findCell() {
                    cell = found
                    build = .showing
                    // Gesehen, sobald es stand: Auch wer die App jetzt schließt, sieht es nicht noch mal.
                    memory.markSeen(.build)
                } else {
                    build = .waiting(waited)
                }
            }
        case .showing:
            if now.towers > 0 { build = .done }
        case .done:
            break
        }
    }

    private func advanceWave(_ now: Situation) {
        switch wave {
        case .waiting(let seconds):
            if playerCalled {
                wave = .done
                memory.markSeen(.wave)
            } else if now.firstWaveStarted {
                // Von selbst gekommen: nicht gelernt, beim nächsten Versuch wieder.
                wave = .done
            } else if now.towers > 0 && now.canCallWave && !now.halted {
                // Erst mit einem Turm: Wer die Hand übersprungen hat, bekommt
                // sonst den Pfeil, bevor er gebaut hat.
                let waited = seconds + now.dt
                if waited >= BattleStyle.guideWaveDelay {
                    wave = .showing
                    memory.markSeen(.wave)
                } else {
                    wave = .waiting(waited)
                }
            }
        case .showing:
            if now.firstWaveStarted || !now.canCallWave { wave = .done }
        case .done:
            break
        }
    }
}

#if DEBUG
/// Was der Einstieg gerade zeigt, für die End-zu-End-Tests (`guide.state`: `none`,
/// `build`, `wave`). Hand und Pfeil sind SpriteKit bzw. ohne Kennung; so liest
/// der Test sie trotzdem. Nur im Debug-Bau, wie `fx.stats`.
struct GuideStateOverlay: View {
    let guide: BattleGuide

    var body: some View {
        Text(guide.shown.name)
            .font(.system(size: 6))
            .opacity(0.02)
            .allowsHitTesting(false)
            .accessibilityIdentifier("guide.state")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
#endif
