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
        /// zweite Tippen verkauft (07-ui-ux.md, Grundsatz 4). `upgradeArmed`
        /// ebenso fürs Aufwerten, weil es Gold kostet (P2-6). `choice`: welche
        /// Spezialisierung vorgemerkt ist, wenn der Turm zwei zur Wahl hat (P3-3).
        case tower(id: Int, sellArmed: Bool = false, upgradeArmed: Bool = false, choice: Specialization? = nil)
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
    /// Zeile der Ergebnistafel aus dem Spielstand („+11 Erz“, R-7b). Die
    /// Schlacht rechnet sie nicht selbst: Erz ist Sache des Fortschritts.
    var reward: String?
    private(set) var paused = false
    /// Zeile auf der Pausentafel nach einem Neustart der App (P2-2): fortgesetzt
    /// oder, nach einem Update, neu begonnen. Verschwindet mit dem ersten „Weiter“.
    private(set) var notice: String?
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
    /// Gold, das Rufen der nächsten Welle jetzt brächte (P2-5). Ganze Zahl aus
    /// der Simulation, damit der Knopf nie mehr verspricht, als gutgeschrieben wird.
    private(set) var callBonus = 0
    /// Steigt mit jeder Gutschrift fürs frühe Rufen; die Goldanzeige zeigt `lastBonus`.
    private(set) var bonusGains = 0
    private(set) var lastBonus = 0
    /// Steigt, wenn ein Kauf an der Höchstzahl scheitert.
    private(set) var limitWarnings = 0
    /// Steigt mit jeder Aufwertung, für Tests und die Ergebnistafel.
    private(set) var towersUpgraded = 0

    /// Rückmeldung an den Finger. Austauschbar, damit Tests mitschreiben können.
    @ObservationIgnored var haptics: @MainActor (Haptic) -> Void
    /// Ton zur eigenen Handlung (P2-3). Stumm, bis die Ansicht ihn verbindet,
    /// damit Tests ohne Lautsprecher laufen.
    @ObservationIgnored var sounds: @MainActor (SoundMoment) -> Void = { _ in }
    /// Stille Zeichen des Einstiegs (P2-8). Ohne `intro` zeigt es nur den Satz
    /// zum ersten Sporenfunken.
    @ObservationIgnored private(set) var guide: BattleGuide!

    init(model: BattleModel, interactive: Bool, intro: Bool = false, memory: GuideMemory = GuideMemory()) {
        self.model = model
        self.interactive = interactive
        gold = model.state.gold
        lives = model.state.fortressLives
        wave = model.state.waveIndex + 1
        outcome = model.state.outcome
        secondsToNextWave = nil
        haptics = { FeedbackPlayer.play($0) }
        refreshCopies()
        guide = BattleGuide(memory: memory, intro: intro, interactive: interactive) { [weak self] in self?.guideCell() }
    }

    /// Zelle für die Hand des Einstiegs: die, von der der günstigste Kampfturm
    /// am meisten Weg abdeckt. Wer dort baut, hat einen guten ersten Turm.
    private func guideCell() -> Cell? {
        let kinds = buildable.filter { model.sim.config.stats(of: $0, level: 1)?.range ?? 0 > 0 }
        guard let kind = kinds.min(by: { cost(of: $0) < cost(of: $1) }),
              let range = model.sim.config.stats(of: kind, level: 1)?.range else { return nil }
        return map.bestCell(radius: range, excluding: model.state.towers.map(\.cell))
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
        if case .tower(_, true, _, _) = selection { return true }
        return false
    }

    var upgradeArmed: Bool {
        if case .tower(_, _, true, _) = selection { return true }
        return false
    }

    /// Gold, das zum Turm fehlt; 0, wenn er bezahlbar ist.
    func missingGold(for kind: TowerKind) -> Int { max(0, cost(of: kind) - gold) }

    var map: MissionMap { model.sim.map }

    func cost(of kind: TowerKind) -> Int { model.sim.config.cost(of: kind) ?? 0 }

    func canAfford(_ kind: TowerKind) -> Bool { gold >= cost(of: kind) }

    // MARK: Zwergenbank (P2-5)

    /// Was das Kreismenü anbietet: die drei Kampftürme, in Mission 2 die Bank dazu.
    var buildable: [TowerKind] { model.sim.config.buildable }
    var bank: BankConfig? { model.sim.config.bank }
    var banksStanding: Int { model.sim.banks(in: model.state) }

    /// Höchstzahl erreicht? Nur die Bank hat eine.
    func atLimit(_ kind: TowerKind) -> Bool {
        guard kind == .bank, let bank else { return false }
        return banksStanding >= bank.limit
    }

    var limitTag: String { BattleTexts.limit(banksStanding, of: bank?.limit ?? 0) }
    var limitReachedText: String { BattleTexts.limitReached(bank?.limit ?? 0) }

    /// Hat die Bank alles ausgezahlt? Dann steht sie nur noch im Weg.
    func isEmpty(_ tower: Tower) -> Bool {
        guard tower.kind == .bank, let bank else { return false }
        return tower.paid >= bank.cap
    }

    var selectedTower: Tower? {
        // `BattleModel` ist nicht beobachtet; erst das Lesen der Kopie meldet der
        // Ansicht, dass sich der Turm ändern kann. Sonst blieb die Zielwahl auf
        // dem Knopf stehen, weil sie weder Gold noch Auswahl ändert.
        _ = shownTower
        guard case .tower(let id, _, _, _) = selection else { return nil }
        return model.state.towers.first { $0.id == id }
    }

    /// Beobachtete Kopie des gewählten Turms (Stufe, Zielwahl, Auszahlung).
    private(set) var shownTower: Tower?

    func refund(for tower: Tower) -> Int { model.sim.refund(for: tower.spent) }

    // MARK: Aufwerten und Zielwahl (P2-6)

    /// Preis der nächsten Stufe, nil, wenn der Turm nicht weiter kann oder die
    /// Mission keine Aufwertung kennt (Mission 1 und 2).
    func upgradeCost(for tower: Tower) -> Int? {
        if let specialization = specialization(for: tower) {
            return model.sim.config.specializations?[specialization]?.cost
        }
        guard tower.level < model.sim.config.maxLevel(of: tower.kind) else { return nil }
        return model.sim.config.upgradeCost(of: tower.kind)
    }

    /// Stufe 3 (P3-1): Auf Stufe 2 nimmt die Spezialisierung den Platz von
    /// „Aufwerten“ ein, mit demselben zweimaligen Tippen. In M5a und M5b gibt
    /// es je Turm eine (S14); bei zwei zur Wahl stehen zwei Sterne (P3-3).
    func specialization(for tower: Tower) -> Specialization? {
        specializations(for: tower).first
    }

    /// Ab Mission 6 stehen zwei zur Wahl (D-077, P3-3), in der Reihenfolge des
    /// Codes. Leer, wenn der Turm nicht spezialisieren kann.
    func specializations(for tower: Tower) -> [Specialization] {
        guard tower.level == 2, tower.specialization == nil else { return [] }
        return model.sim.config.specializations(for: tower.kind)
    }

    func cost(of specialization: Specialization) -> Int? {
        model.sim.config.specializations?[specialization]?.cost
    }

    /// Die vorgemerkte Spezialisierung: bei einer Wahl die angetippte, sonst die einzige.
    var armedSpecialization: Specialization? {
        guard case .tower(_, _, true, let choice) = selection, let tower = selectedTower else { return nil }
        return choice ?? specialization(for: tower)
    }

    /// Ein Stern bei zwei zur Wahl (P3-3): Das erste Tippen merkt ihn vor und
    /// zeigt seine Wirkung, ein Tippen auf den anderen Stern schaltet nur um,
    /// das zweite Tippen auf denselben kauft.
    func specialize(_ specialization: Specialization) {
        guard interactive, case .tower(let id, _, let armed, let choice) = selection, let tower = selectedTower,
              specializations(for: tower).contains(specialization), let cost = cost(of: specialization) else { return }
        guard gold >= cost else {
            goldWarnings += 1
            feedback(.cannotAfford)
            return
        }
        if armed, (choice ?? self.specialization(for: tower)) == specialization {
            model.enqueue(.specialize(towerID: id, specialization))
            selection = .tower(id: id)
        } else {
            selection = .tower(id: id, upgradeArmed: true, choice: specialization)
            feedback(.preview)
        }
    }

    /// Zielwahl ab Stufe 2 und nur bei Türmen mit Einzelziel (07, „Zielwahl“).
    func hasTargetMode(_ tower: Tower) -> Bool {
        tower.level >= 2 && model.sim.config.stats(of: tower)?.targeting == .first
    }

    /// Erstes Tippen zeigt Stufe 2 in Tafel und Kreis, zweites kauft. Die
    /// Auswahl bleibt am Turm, damit man gleich die Zielwahl sieht.
    func upgrade() {
        guard interactive, case .tower(let id, _, let armed, _) = selection, let tower = selectedTower,
              let cost = upgradeCost(for: tower) else { return }
        // Bei zwei zur Wahl gibt es kein „Aufwerten“, nur die Sterne (`specialize`).
        guard specializations(for: tower).count < 2 else { return }
        guard gold >= cost else {
            goldWarnings += 1
            feedback(.cannotAfford)
            return
        }
        if armed {
            if let specialization = specialization(for: tower) {
                model.enqueue(.specialize(towerID: id, specialization))
            } else {
                model.enqueue(.upgrade(towerID: id))
            }
            selection = .tower(id: id)
        } else {
            selection = .tower(id: id, upgradeArmed: true)
            feedback(.preview)
        }
    }

    /// Schaltet weiter: Erster → Letzter → Stärkster. Kostet nichts, also
    /// ohne zweites Tippen.
    func cycleTargetMode() {
        guard interactive, let tower = selectedTower, hasTargetMode(tower) else { return }
        model.enqueue(.setTargetMode(towerID: tower.id, tower.targetMode.next))
        feedback(.preview)
    }

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
            // Beim ersten Tippen auf Aufwerten zeigt der Kreis schon die nächste Stufe (07).
            guard let tower = selectedTower, let stats = previewStats(of: tower) else { return nil }
            return (center: tower.cell.center, range: stats.range)
        }
    }

    private func previewStats(of tower: Tower) -> TowerConfig? {
        let config = model.sim.config
        guard upgradeArmed else { return config.stats(of: tower) }
        if let specialization = armedSpecialization {
            return config.stats(of: tower.kind, specialization: specialization)
        }
        return config.stats(of: tower.kind, level: tower.level + 1)
    }

    // MARK: Eingaben

    func tap(_ cell: Cell?) {
        guide.skip()
        guard interactive, !model.state.isOver, !surrendered, let cell else { return dismiss() }
        if let tower = model.state.towers.first(where: { $0.cell == cell }) {
            if case .tower(tower.id, _, _, _) = selection {
                selection = .none
            } else {
                selection = .tower(id: tower.id)
                feedback(.selectCell)
            }
        } else if map.isBuildable(cell) {
            if case .cell(cell, _) = selection {
                selection = .none
            } else {
                selection = .cell(cell, choice: nil)
                feedback(.selectCell)
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
        guard !atLimit(kind) else {
            // Wie beim Gold: kein Befehl, nur spürbar, warum nichts geschieht.
            limitWarnings += 1
            haptics(FeedbackPlayer.haptic(for: .cannotAfford))
            return
        }
        guard canAfford(kind) else {
            // Gedimmt, aber antippbar: Man soll spüren, warum nichts geschieht
            // (07-ui-ux.md, „Bauen“). Es geht kein Befehl hinaus.
            goldWarnings += 1
            feedback(.cannotAfford)
            return
        }
        if choice == kind {
            model.enqueue(.build(kind, cell))
            selection = .none
        } else {
            selection = .cell(cell, choice: kind)
            feedback(.preview)
        }
    }

    /// Erstes Tippen fragt „Sicher?“, zweites verkauft.
    func sell() {
        guard interactive, case .tower(let id, let armed, _, _) = selection else { return }
        if armed {
            model.enqueue(.sell(towerID: id))
            selection = .none
        } else {
            selection = .tower(id: id, sellArmed: true)
            feedback(.armSell)
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
            feedback(.selectCell)
        } else {
            feedback(.cannotAfford)
        }
    }

    /// Wurf beim Zielen. Daneben gezielt kostet nichts und lässt das Zielen
    /// offen, damit man gleich neu ansetzt (r-3-steinregen.md).
    func cast(at point: Point?) {
        guard aiming else { return }
        guard let point, let target = snappedTarget(for: point) else {
            feedback(.cannotAfford)
            return
        }
        model.enqueue(.useAbility(target))
        selection = .none
    }

    func callNextWave() {
        guard canCallNextWave else { return }
        model.enqueue(.callNextWave)
        guide.playerCalledWave()
        feedback(.callWave)
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
        // Aufgeben endet wie eine Niederlage, auch in der Musik.
        sounds(.missionEnded(won: false))
    }

    /// Eine Bedienhandlung: spüren und hören.
    private func feedback(_ action: UserAction) {
        haptics(FeedbackPlayer.haptic(for: action))
        sounds(.user(action))
    }

    /// Pause hält nur die Uhr an; der Zustand bleibt unberührt, deshalb gehört
    /// sie nicht in die Simulation.
    func togglePause() {
        guard !isFinished else { return }
        paused.toggle()
        model.paused = paused
        if !paused { notice = nil }
    }

    /// Beginnt angehalten mit Hinweis: Wer die App wieder öffnet, soll nicht
    /// mitten in eine laufende Welle fallen (P2-2).
    func startPaused(notice: String) {
        guard !isFinished else { return }
        paused = true
        model.paused = true
        self.notice = notice
    }

    /// Darf der Stand jetzt gesichert werden? Nur das eigene Spiel und nur, solange
    /// es läuft: Ein Ergebnis hat der Fortschritt schon, eine Vorführung ist keins.
    var isSuspendable: Bool { interactive && !isFinished }

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
    func afterFrame(events: [Event] = [], dt: Double = 0) {
        for event in events { count(event) }
        refreshCopies()
        let state = model.state
        guide.update(BattleGuide.Situation(
            dt: dt, towers: state.towers.count, firstWaveStarted: state.waveIndex >= 0,
            canCallWave: canCallNextWave, halted: paused || isFinished || aiming || notice != nil))
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
        notice = nil
        paused = false
        surrendered = false
        towersBuilt = 0
        towersUpgraded = 0
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
        case .commandRejected(_, reason: .limitReached): limitWarnings += 1
        case .earlyCallBonus(let gold):
            lastBonus = gold
            bonusGains += 1
        case .towerUpgraded: towersUpgraded += 1
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
        let tower: Tower? = if case .tower(let id, _, _, _) = selection { state.towers.first { $0.id == id } } else { nil }
        if shownTower != tower { shownTower = tower }
        if gold != state.gold { gold = state.gold }
        if lives != state.fortressLives { lives = state.fortressLives }
        if let ability = model.sim.config.ability {
            let total = Double(model.sim.ticks(ability.cooldown))
            let left = Double(max(0, state.ability.readyTick - state.tick))
            let charge = ((1 - left / max(total, 1)) * 100).rounded(.down) / 100
            if abilityCharge != charge { abilityCharge = charge }
        }
        let bonus = model.sim.earlyCallBonus(in: state)
        if callBonus != bonus { callBonus = bonus }
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
