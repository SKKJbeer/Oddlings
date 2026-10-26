import Foundation
import Observation
import OddlingsCore

/// Bedienung der Mission (WP-12). Übersetzt Tippen in Befehle an das Modell
/// und hält fest, was gerade ausgewählt ist. Den Spielzustand ändert sie nie
/// selbst (Architekturregel 2): Ob ein Bau gelingt, entscheidet die Simulation
/// im nächsten Schritt, und eine Ablehnung kommt als Ereignis zurück.
@Observable
@MainActor
final class BattleController {
    enum Selection: Equatable {
        case none
        /// Freie Bauzelle. `choice` ist der Turm, dessen Reichweite gerade
        /// gezeigt wird; ein zweiter Tipp auf ihn baut.
        case cell(Cell, choice: TowerKind?)
        /// Gebauter Turm. `sellArmed`: Verkaufen wurde einmal angetippt, das
        /// zweite Tippen verkauft (07-ui-ux.md, Grundsatz 4).
        case tower(id: Int, sellArmed: Bool = false)
        /// Steinregen ist gewählt; der nächste Tipp auf die Karte wirft (07).
        case aiming
    }

    @ObservationIgnored let model: BattleModel
    /// Beim Zuschauen (Mitspieler) nimmt die Mission keine Eingaben an.
    @ObservationIgnored let interactive: Bool
    private(set) var selection: Selection = .none
    /// Kopie für die Oberfläche; wird nur bei Änderung gesetzt, damit SwiftUI
    /// nicht in jedem Bild neu zeichnet.
    private(set) var gold: Int
    private(set) var lives: Int
    /// Laufende Welle, ab 1 gezählt; 0 vor der ersten.
    private(set) var wave: Int
    /// Ganze Sekunden bis zur nächsten Welle, nil wenn keine mehr kommt.
    private(set) var secondsToNextWave: Int?
    /// Länge des laufenden Countdowns in Sekunden, für den Ring am Welle-Knopf.
    private(set) var countdownTotal = 1
    private(set) var outcome: Outcome?
    private(set) var paused = false
    private(set) var speed = 1
    /// „Aufgeben“ in der Pause: Die Mission bleibt angehalten, die Tafel zeigt
    /// die Niederlage. Die Simulation bekommt dafür keinen Befehl und meldet
    /// kein Ergebnis, das sie nicht gerechnet hat.
    private(set) var surrendered = false

    // Aus Ereignissen gezählt, für Ergebnistafel und Rückmeldung.
    private(set) var towersBuilt = 0
    private(set) var enemiesDefeated = 0
    /// Steigt bei jedem Durchbruch; die Lebensanzeige wackelt bei jeder Änderung.
    private(set) var leaks = 0
    /// Steigt, wenn ein Kauf am Gold scheitert; die Goldanzeige blinkt.
    private(set) var goldWarnings = 0
    /// Ladeanteil des Steinregens, 0 bis 1. In Hundertsteln, damit der Knopf
    /// nicht in jedem Bild neu zeichnet.
    private(set) var abilityCharge = 1.0

    /// Rückmeldung an den Finger. Austauschbar, damit Tests mitschreiben können.
    @ObservationIgnored var haptics: @MainActor (Haptic) -> Void

    init(model: BattleModel, interactive: Bool) {
        self.model = model
        self.interactive = interactive
        gold = model.state.gold
        lives = model.state.fortressLives
        wave = model.state.waveIndex + 1
        outcome = model.state.outcome
        secondsToNextWave = nil
        haptics = { FeedbackPlayer.play($0) }
        refreshCopies()
    }

    var waveCount: Int { model.sim.config.waves.count }

    /// Darf man die nächste Welle jetzt rufen? Nur im eigenen Spiel, solange
    /// noch eine aussteht.
    var canCallNextWave: Bool { interactive && shownOutcome == nil && secondsToNextWave != nil }

    /// Was die Ergebnistafel zeigt: das Ergebnis der Simulation oder, nach
    /// „Aufgeben“, die Niederlage.
    var shownOutcome: Outcome? { outcome ?? (surrendered ? .lost : nil) }

    var isFinished: Bool { shownOutcome != nil }

    /// Spielzeit aus dem Takt, nicht aus der Uhr: Pause und 2× zählen richtig.
    var elapsedSeconds: Int { model.state.tick / model.sim.config.simulation.ticksPerSecond }

    /// Wellen, die ganz überstanden sind. Bei einer Niederlage ist die laufende
    /// nicht gehalten.
    var wavesHeld: Int { outcome == .won ? waveCount : max(0, wave - 1) }

    /// Zelle, an der das Kreismenü hängt.
    var anchorCell: Cell? {
        switch selection {
        case .none, .aiming: nil
        case .cell(let cell, _): cell
        case .tower: selectedTower?.cell
        }
    }

    var sellArmed: Bool {
        if case .tower(_, true) = selection { return true }
        return false
    }

    /// Gold, das zum Turm fehlt; 0, wenn er bezahlbar ist.
    func missingGold(for kind: TowerKind) -> Int { max(0, cost(of: kind) - gold) }

    var map: MissionMap { model.sim.map }

    func cost(of kind: TowerKind) -> Int { model.sim.config.towers[kind]?.cost ?? 0 }

    func canAfford(_ kind: TowerKind) -> Bool { gold >= cost(of: kind) }

    var selectedTower: Tower? {
        guard case .tower(let id, _) = selection else { return nil }
        return model.state.towers.first { $0.id == id }
    }

    func refund(for tower: Tower) -> Int { model.sim.refund(for: tower.spent) }

    /// Nur wenn die Mission eine Fähigkeit hat und man selbst spielt (03).
    var hasAbility: Bool { interactive && model.sim.config.ability != nil }
    var abilityReady: Bool { hasAbility && abilityCharge >= 1 && !isFinished }
    var aiming: Bool { selection == .aiming }
    var abilityRadius: Double { model.sim.config.ability?.radius ?? 0 }
    /// Welche Fähigkeit der Knopf trägt; das Volk bestimmt sie (R-4).
    var abilityKind: AbilityKind { model.sim.config.ability?.kind ?? .stoneRain }

    /// Wohin ein Wurf auf `point` fiele, oder nil, wenn er zu weit neben dem
    /// Weg läge. Dieselbe Rechnung wie die Simulation, damit die Vorschau nie
    /// etwas verspricht, das abgelehnt wird.
    func snappedTarget(for point: Point) -> Point? {
        guard let ability = model.sim.config.ability else { return nil }
        let center = map.path.nearestPoint(to: point)
        return center.distance(to: point) <= ability.snapDistance ? center : nil
    }

    /// Reichweite, die die Szene um die Auswahl zeichnet, in Feldern.
    var previewRange: (center: Point, range: Double)? {
        switch selection {
        case .none, .aiming, .cell(_, choice: nil):
            return nil
        case .cell(let cell, let kind?):
            guard let stats = model.sim.config.towers[kind] else { return nil }
            return (center: cell.center, range: stats.range)
        case .tower:
            guard let tower = selectedTower, let stats = model.sim.config.towers[tower.kind] else { return nil }
            return (center: tower.cell.center, range: stats.range)
        }
    }

    // MARK: Eingaben

    func tap(_ cell: Cell?) {
        guard interactive, !model.state.isOver, !surrendered, let cell else { return dismiss() }
        if let tower = model.state.towers.first(where: { $0.cell == cell }) {
            if case .tower(tower.id, _) = selection {
                selection = .none
            } else {
                selection = .tower(id: tower.id)
                haptics(FeedbackPlayer.haptic(for: .selectCell))
            }
        } else if map.isBuildable(cell) {
            if case .cell(cell, _) = selection {
                selection = .none
            } else {
                selection = .cell(cell, choice: nil)
                haptics(FeedbackPlayer.haptic(for: .selectCell))
            }
        } else {
            // Weg oder Rand: Dort kann nie etwas stehen, also kein Menü und keine
            // Fehlermeldung. Der Tipp schließt nur, was offen war.
            selection = .none
        }
    }

    /// Erster Tipp zeigt die Reichweite, zweiter baut. So sieht man vor dem
    /// Bezahlen, was der Turm abdeckt (01-core-gameplay.md, Bedienung).
    func choose(_ kind: TowerKind) {
        guard interactive, case .cell(let cell, let choice) = selection else { return }
        guard canAfford(kind) else {
            // Gedimmt, aber antippbar: Man soll spüren, warum nichts geschieht
            // (07-ui-ux.md, „Bauen“). Es geht kein Befehl hinaus.
            goldWarnings += 1
            haptics(FeedbackPlayer.haptic(for: .cannotAfford))
            return
        }
        if choice == kind {
            model.enqueue(.build(kind, cell))
            selection = .none
        } else {
            selection = .cell(cell, choice: kind)
            haptics(FeedbackPlayer.haptic(for: .preview))
        }
    }

    /// Erstes Tippen fragt „Sicher?“, zweites verkauft.
    func sell() {
        guard interactive, case .tower(let id, let armed) = selection else { return }
        if armed {
            model.enqueue(.sell(towerID: id))
            selection = .none
        } else {
            selection = .tower(id: id, sellArmed: true)
            haptics(FeedbackPlayer.haptic(for: .armSell))
        }
    }

    /// Knopf unten rechts: öffnet das Zielen und schließt dabei das Kreismenü,
    /// ein zweiter Druck bricht ab (07).
    func toggleAim() {
        guard hasAbility, !isFinished else { return }
        if aiming {
            selection = .none
        } else if abilityReady {
            selection = .aiming
            haptics(FeedbackPlayer.haptic(for: .selectCell))
        } else {
            haptics(FeedbackPlayer.haptic(for: .cannotAfford))
        }
    }

    /// Wurf beim Zielen. Daneben gezielt kostet nichts und lässt das Zielen
    /// offen, damit man gleich neu ansetzt (r-3-steinregen.md).
    func cast(at point: Point?) {
        guard aiming else { return }
        guard let point, let target = snappedTarget(for: point) else {
            haptics(FeedbackPlayer.haptic(for: .cannotAfford))
            return
        }
        model.enqueue(.useAbility(target))
        selection = .none
    }

    func callNextWave() {
        guard canCallNextWave else { return }
        model.enqueue(.callNextWave)
        haptics(FeedbackPlayer.haptic(for: .callWave))
    }

    /// Beendet die Mission aus der Pause heraus und zeigt die Niederlage-Tafel
    /// mit dem Stand von jetzt.
    func giveUp() {
        guard interactive, outcome == nil, !surrendered else { return }
        surrendered = true
        selection = .none
        paused = false
        model.paused = true
        haptics(.error)
    }

    /// Pause hält nur die Uhr an; der Zustand bleibt unberührt, deshalb gehört
    /// sie nicht in die Simulation.
    func togglePause() {
        guard !isFinished else { return }
        paused.toggle()
        model.paused = paused
    }

    /// Hält an, wenn die App in den Hintergrund geht. Wer zurückkommt, soll
    /// keine Welle verpasst haben.
    func pauseForBackground() {
        guard !isFinished, !paused else { return }
        togglePause()
    }

    /// Wechselt zwischen 1× und 2×. Die Stufe ist Bedienung, kein Spielwert:
    /// Die Simulation rechnet bei 2× dieselben Schritte, nur dichter.
    func toggleSpeed() {
        speed = speed == 1 ? BattleStyle.fastSpeed : 1
        model.speed = speed
    }

    func dismiss() {
        if selection != .none { selection = .none }
    }

    /// Nach jedem Bild: Kopien nachziehen und eine Auswahl schließen, die es
    /// nicht mehr gibt (Turm verkauft, Zelle inzwischen belegt, Mission vorbei).
    func afterFrame(events: [Event] = []) {
        for event in events { count(event) }
        refreshCopies()
        let state = model.state
        switch selection {
        case .none:
            break
        case _ where state.isOver || surrendered:
            selection = .none
        case .tower:
            if selectedTower == nil { selection = .none }
        case .cell(let cell, _):
            if state.towers.contains(where: { $0.cell == cell }) { selection = .none }
        case .aiming:
            if !abilityReady { selection = .none }
        }
    }

    func restart() {
        selection = .none
        paused = false
        surrendered = false
        towersBuilt = 0
        enemiesDefeated = 0
        model.paused = false
        refreshCopies()
    }

    private func count(_ event: Event) {
        switch event {
        case .towerBuilt: towersBuilt += 1
        case .enemyKilled: enemiesDefeated += 1
        case .enemyLeaked: leaks += 1
        case .commandRejected(_, reason: .notEnoughGold): goldWarnings += 1
        default: break
        }
        // Nur im eigenen Spiel: Beim Zuschauen baut der Mitspieler, und das
        // soll nicht in der Hand vibrieren.
        if interactive, let haptic = FeedbackPlayer.haptic(for: event) { haptics(haptic) }
    }

    /// Setzt nur, was sich geändert hat: Jede Zuweisung an eine beobachtete
    /// Eigenschaft lässt SwiftUI neu zeichnen, und das 60-mal je Sekunde.
    private func refreshCopies() {
        let state = model.state
        if gold != state.gold { gold = state.gold }
        if lives != state.fortressLives { lives = state.fortressLives }
        if let ability = model.sim.config.ability {
            let total = Double(model.sim.ticks(ability.cooldown))
            let left = Double(max(0, state.ability.readyTick - state.tick))
            let charge = ((1 - left / max(total, 1)) * 100).rounded(.down) / 100
            if abilityCharge != charge { abilityCharge = charge }
        }
        if wave != state.waveIndex + 1 { wave = state.waveIndex + 1 }
        if outcome != state.outcome {
            outcome = state.outcome
            paused = false
            model.paused = false
        }
        let seconds = state.nextWaveTick.map { due in
            let ticks = max(0, due - state.tick)
            let perSecond = model.sim.config.simulation.ticksPerSecond
            return (ticks + perSecond - 1) / perSecond
        }
        if secondsToNextWave != seconds {
            // Ein Countdown beginnt, wo die Restzeit springt statt sinkt.
            if let seconds, seconds > (secondsToNextWave ?? 0) { countdownTotal = max(1, seconds) }
            secondsToNextWave = seconds
        }
    }
}
