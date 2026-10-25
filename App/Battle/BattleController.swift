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
        case tower(id: Int)
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
    private(set) var outcome: Outcome?
    private(set) var paused = false
    private(set) var speed = 1

    init(model: BattleModel, interactive: Bool) {
        self.model = model
        self.interactive = interactive
        gold = model.state.gold
        lives = model.state.fortressLives
        wave = model.state.waveIndex + 1
        outcome = model.state.outcome
        secondsToNextWave = nil
        refreshCopies()
    }

    var waveCount: Int { model.sim.config.waves.count }

    /// Darf man die nächste Welle jetzt rufen? Nur im eigenen Spiel, solange
    /// noch eine aussteht.
    var canCallNextWave: Bool { interactive && outcome == nil && secondsToNextWave != nil }

    var map: MissionMap { model.sim.map }

    func cost(of kind: TowerKind) -> Int { model.sim.config.towers[kind]?.cost ?? 0 }

    func canAfford(_ kind: TowerKind) -> Bool { gold >= cost(of: kind) }

    var selectedTower: Tower? {
        guard case .tower(let id) = selection else { return nil }
        return model.state.towers.first { $0.id == id }
    }

    func refund(for tower: Tower) -> Int { model.sim.refund(for: tower.spent) }

    /// Reichweite, die die Szene um die Auswahl zeichnet, in Feldern.
    var previewRange: (center: Point, range: Double)? {
        switch selection {
        case .none, .cell(_, choice: nil):
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
        guard interactive, !model.state.isOver, let cell else { return dismiss() }
        if let tower = model.state.towers.first(where: { $0.cell == cell }) {
            selection = selection == .tower(id: tower.id) ? .none : .tower(id: tower.id)
        } else if map.isBuildable(cell) {
            if case .cell(cell, _) = selection { selection = .none } else { selection = .cell(cell, choice: nil) }
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
        if choice == kind {
            model.enqueue(.build(kind, cell))
            selection = .none
        } else {
            selection = .cell(cell, choice: kind)
        }
    }

    func sell() {
        guard interactive, case .tower(let id) = selection else { return }
        model.enqueue(.sell(towerID: id))
        selection = .none
    }

    func callNextWave() {
        guard canCallNextWave else { return }
        model.enqueue(.callNextWave)
    }

    /// Pause hält nur die Uhr an; der Zustand bleibt unberührt, deshalb gehört
    /// sie nicht in die Simulation.
    func togglePause() {
        guard outcome == nil else { return }
        paused.toggle()
        model.paused = paused
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
    func afterFrame() {
        refreshCopies()
        let state = model.state
        switch selection {
        case .none:
            break
        case _ where state.isOver:
            selection = .none
        case .tower:
            if selectedTower == nil { selection = .none }
        case .cell(let cell, _):
            if state.towers.contains(where: { $0.cell == cell }) { selection = .none }
        }
    }

    func restart() {
        selection = .none
        paused = false
        model.paused = false
        refreshCopies()
    }

    /// Setzt nur, was sich geändert hat: Jede Zuweisung an eine beobachtete
    /// Eigenschaft lässt SwiftUI neu zeichnen, und das 60-mal je Sekunde.
    private func refreshCopies() {
        let state = model.state
        if gold != state.gold { gold = state.gold }
        if lives != state.fortressLives { lives = state.fortressLives }
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
        if secondsToNextWave != seconds { secondsToNextWave = seconds }
    }
}
