import OddlingsCore
import SpriteKit

/// Zeigt, was die Simulation tut (WP-11). Die Szene liest Zustand und
/// Ereignisse und ändert nichts davon (Architekturregel 2). Effekte hängen an
/// Ereignissen und laufen über den `FxDirector` (Architekturregel 3, D-050);
/// was dauerhaft sichtbar ist (Türme, Gegner samt Laufhaltung, Lebensbalken,
/// Verlangsamung), folgt dem Zustand.
@MainActor
final class BattleScene: SKScene {
    let model: BattleModel
    /// Bedienung; nil beim reinen Zuschauen und in Tests ohne Eingaben.
    var controller: BattleController?
    private(set) var towerNodes: [Int: TowerNode] = [:]
    private(set) var enemyNodes: [Int: EnemyNode] = [:]
    let fx: FxDirector
    /// Ton hängt wie das Bild an Ereignissen (P2-3). Nil in Tests ohne Ton.
    var audio: AudioDirector?

    /// Alles, was beim Bildschirmwackeln mitwackelt. Die Szene selbst bleibt
    /// stehen, damit Tippen und Lagerechnung unberührt sind.
    private let world: SKNode
    private let ground = SKNode()
    private let towerLayer = SKNode()
    private let enemyLayer = SKNode()
    let effectLayer: SKNode
    private let fortress = SKShapeNode()
    private let fortressHit = SKShapeNode()
    private var fortressRest = CGPoint.zero
    private let selectionLayer = SKNode()
    private var shownSelection: BattleController.Selection = .none
    /// Was im nächsten Abgleich mit Auftritt erscheint. Nach einer neuen
    /// Bildschirmgröße entstehen die Nodes neu, dann ohne Auftritt.
    private var pendingSpawns: Set<Int> = []
    /// Der Hinweis auf die Panzerung kommt einmal je Mission, auch über einen
    /// Neustart hinweg: Wer neu anfängt, hat ihn schon gelesen (P2-10).
    private var armorHintShown = false
    /// „Sporenfunke!“ springt beim ersten Funken jeder Mission auf (P2-8).
    private var sparkCalloutShown = false
    /// Was vom Einstieg gerade auf der Karte steht (Hand).
    private var shownGuide: BattleGuide.Shown = .none
    private var pendingBuilds: Set<Int> = []
    private(set) var layout: BoardLayout
    private var field: CGFloat { layout.field }
    private var lastTime: TimeInterval?
    /// Ereignisse des letzten Bildes, für Tests.
    private(set) var lastEvents: [Event] = []
    #if DEBUG
    private var probe: FxProbe?
    #endif

    init(model: BattleModel) {
        self.model = model
        let size = CGSize(width: 844, height: 390)
        let layout = BoardLayout(size: size, map: model.sim.map)
        self.layout = layout
        let world = SKNode(), effects = SKNode()
        self.world = world
        effectLayer = effects
        fx = FxDirector(layer: effects, world: world, field: layout.field)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = BattleStyle.background
        #if DEBUG
        probe = FxProbe.fromArguments()
        #endif
        addChild(world)
        for (layer, z) in [(ground, 0), (selectionLayer, 5), (towerLayer, 10), (enemyLayer, 20), (effectLayer, 30)] {
            layer.zPosition = CGFloat(z)
            world.addChild(layer)
        }
        layoutMap()
        fx.onCombo = { [weak self] point in self?.combo(at: point) }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("nicht benutzt") }

    override func didChangeSize(_ oldSize: CGSize) { layoutMap() }

    override func update(_ currentTime: TimeInterval) {
        let frameTime = lastTime.map { currentTime - $0 } ?? 0
        lastTime = currentTime
        frame(after: frameTime)
        #if DEBUG
        probe?.add(frameTime)
        #endif
    }

    /// Ein Bild: fällige Schritte rechnen, Effekte auslösen, Zustand zeigen.
    /// Eigene Methode, damit Tests ohne Bildschirm Bilder erzeugen können.
    func frame(after frameTime: TimeInterval) {
        let events = model.advance(by: frameTime)
        lastEvents = events
        // Angehalten steht auch jeder Effekt; bei 2× laufen Effekte in Echtzeit.
        let fxTime = model.paused ? 0 : min(frameTime, BattleStyle.maxCatchUp)
        // Was in diesem Takt erscheint, kann im selben Takt schon schießen oder
        // getroffen werden: Seine Node muss stehen, bevor der Pfeil sie sucht.
        addNewPieces()
        // Effekte vor dem Abgleich, solange getötete Gegner noch eine Node haben.
        for event in events { play(event) }
        sync(dt: fxTime)
        fx.advance(by: fxTime)
        controller?.afterFrame(events: events, dt: fxTime)
        showSelection()
        showGuide()
    }

    func restart() {
        model.restart()
        audio?.startBattle()
        fx.reset()
        clearPieces()
        sparkCalloutShown = false
        shownGuide = .none
        controller?.restart()
        sync(dt: 0)
        showSelection()
    }

    /// Hand des Einstiegs auf die Zelle, die der Guide nennt. Sie fängt kein
    /// Tippen ab: Die Szene sucht die Zelle aus der Lage, nicht aus der Node.
    private func showGuide() {
        let now = controller?.guide.shown ?? .none
        guard now != shownGuide else { return }
        shownGuide = now
        if case .build(let cell) = now {
            fx.guideTap(at: toScene(cell.center))
        } else {
            fx.clearGuide()
        }
    }

    /// Erster Sporenfunke der Mission: das Wort, beim ersten Mal überhaupt mit
    /// dem Satz, der die Synergie benennt (K8).
    private func combo(at point: CGPoint) {
        guard !sparkCalloutShown else { return }
        sparkCalloutShown = true
        fx.sparkCallout(at: point, sentence: controller?.guide.takeSparkSentence() == true, bounds: size)
    }

    private func clearPieces() {
        towerLayer.removeAllChildren()
        enemyLayer.removeAllChildren()
        towerNodes = [:]
        enemyNodes = [:]
        pendingSpawns = []
        pendingBuilds = []
    }

    // MARK: Eingabe

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if controller?.aiming == true {
            controller?.cast(at: layout.fieldPoint(atScene: location))
        } else {
            controller?.tap(layout.cell(atScene: location))
        }
        showSelection()
    }

    /// Markierung der gewählten Zelle und Reichweite. Nur neu gebaut, wenn sich
    /// die Auswahl ändert, nicht in jedem Bild.
    private func showSelection() {
        let selection = controller?.selection ?? .none
        guard selection != shownSelection else { return }
        shownSelection = selection
        selectionLayer.removeAllChildren()
        let cell: Cell?
        switch selection {
        case .none: cell = nil
        case .cell(let c, _): cell = c
        case .tower: cell = controller?.selectedTower?.cell
        case .aiming: cell = nil
        }
        guard let cell else { return }
        let mark = SKShapeNode(rectOf: CGSize(width: field, height: field), cornerRadius: field * 0.12)
        mark.strokeColor = BattleStyle.selection
        mark.lineWidth = max(2, field * 0.05)
        mark.fillColor = BattleStyle.selection.withAlphaComponent(0.15)
        mark.position = toScene(cell.center)
        selectionLayer.addChild(mark)
        if let preview = controller?.previewRange {
            let ring = SKShapeNode(circleOfRadius: CGFloat(preview.range) * field)
            ring.strokeColor = BattleStyle.selection
            ring.lineWidth = max(1.5, field * 0.03)
            ring.fillColor = BattleStyle.rangeFill
            ring.position = toScene(preview.center)
            selectionLayer.addChild(ring)
        }
    }

    // MARK: Karte

    /// Felder → Punkte. Die Karte zählt y von oben, SpriteKit von unten.
    private func toScene(_ point: Point) -> CGPoint { layout.scenePoint(point) }

    private func layoutMap() {
        guard size.width > 0, size.height > 0 else { return }
        let map = model.sim.map
        layout = BoardLayout(size: size, map: map)

        ground.removeAllChildren()
        let painted = BattleSprites.ground(missionID: model.sim.config.mission.id, layout: layout)
        if let painted { ground.addChild(painted) }
        let inset = BattleStyle.buildZoneInset * field
        for cell in map.buildableCells {
            let tile = SKSpriteNode(color: BattleStyle.buildZone,
                                    size: CGSize(width: field - 2 * inset, height: field - 2 * inset))
            tile.position = toScene(cell.center)
            ground.addChild(tile)
        }
        if painted == nil {
            let line = CGMutablePath()
            for (index, point) in map.path.points.enumerated() {
                if index == 0 { line.move(to: toScene(point)) } else { line.addLine(to: toScene(point)) }
            }
            let pathNode = SKShapeNode(path: line)
            pathNode.strokeColor = BattleStyle.path
            pathNode.lineWidth = BattleStyle.pathWidth * field
            pathNode.lineCap = .round
            pathNode.lineJoin = .round
            ground.addChild(pathNode)
        }

        // Die Festung sitzt, wo der Weg die Karte verlässt.
        let end = map.path.points[map.path.points.count - 1]
        let gate = Point(x: min(end.x, Double(map.width)), y: end.y)
        fortress.path = CGPath(roundedRect: CGRect(x: (BattleStyle.fortressOffset.x - 0.6) * field, y: -field * 0.9,
                                                   width: field * 1.2, height: field * 1.8),
                               cornerWidth: field * 0.2, cornerHeight: field * 0.2, transform: nil)
        fortress.removeAllChildren()
        if let picture = BattleSprites.fortress(field: field) {
            // Das Bild ersetzt die Form; die Form bleibt als unsichtbarer Träger
            // für das Aufblitzen bei einem Durchbruch.
            fortress.fillColor = .clear
            fortress.strokeColor = .clear
            picture.position = CGPoint(x: BattleStyle.fortressOffset.x * field, y: -BattleStyle.fortressOffset.y * field)
            fortress.addChild(picture)
        } else {
            fortress.fillColor = BattleStyle.fortress
            fortress.strokeColor = .black
        }
        fortress.position = toScene(gate)
        fortress.zPosition = BattleStyle.fortressZ
        fortressRest = fortress.position
        fortressHit.path = fortress.path
        fortressHit.fillColor = BattleStyle.leak
        fortressHit.strokeColor = .clear
        fortressHit.alpha = 0
        fortress.addChild(fortressHit)
        fortress.removeFromParent()
        ground.addChild(fortress)

        // Größen hängen am Feld: bei neuer Größe alles neu aufbauen.
        fx.reset()
        fx.field = field
        clearPieces()
        shownSelection = .none
        // Die Hand ging mit `fx.reset`; das nächste Bild stellt sie neu an ihre Zelle.
        shownGuide = .none
        sync(dt: 0)
        // Die Mauer kommt sonst nur mit `barrierRaised`. Nach neuer Größe und in
        // einer fortgesetzten Mission (P2-2) steht sie schon im Zustand.
        if let barrier = model.state.ability.barrier { raiseWall(at: barrier.distance) }
        showSelection()
    }

    // MARK: Zustand

    /// Gleicht Nodes mit dem Zustand ab. Danach gibt es für jeden Turm und
    /// jeden Gegner genau eine Node (Test in BattleSceneTests); sterbende und
    /// versinkende gehören dem Director.
    func sync(dt: Double) {
        let state = model.state
        var liveTowers: [Int: Bool] = [:]
        for tower in state.towers {
            liveTowers[tower.id] = true
            let node = towerNodes[tower.id] ?? makeTowerNode(tower)
            if pendingBuilds.remove(tower.id) != nil { fx.build(node) }
            node.idle(time: fx.time, still: fx.reduceMotion)
            if tower.kind == .bank, let bank = model.sim.config.bank { node.showBank(paid: tower.paid, cap: bank.cap) }
            node.showLevel(tower.level, field: field)
        }
        for (id, node) in towerNodes where liveTowers[id] == nil {
            node.removeFromParent()
            towerNodes[id] = nil
        }

        var before: [Int: Double] = [:]
        for enemy in model.previous.enemies { before[enemy.id] = enemy.distance }
        let t = model.interpolation
        let path = model.sim.map.path
        var liveEnemies: [Int: Bool] = [:]
        for enemy in state.enemies {
            liveEnemies[enemy.id] = true
            let node = enemyNodes[enemy.id] ?? makeEnemyNode(enemy)
            let appeared = pendingSpawns.remove(enemy.id) != nil
            let from = before[enemy.id] ?? enemy.distance
            let distance = from + (enemy.distance - from) * t
            let here = path.position(at: distance)
            node.position = toScene(here)
            node.zPosition = 1 - node.position.y / max(size.height, 1)
            // Blick in Laufrichtung, aus einem Stück Weg voraus: An senkrechten
            // Stücken bleibt die letzte Richtung, statt zu flackern.
            let ahead = path.position(at: distance + FxStyle.facingLookahead)
            if abs(ahead.x - here.x) > FxStyle.facingThreshold { node.facing = ahead.x > here.x ? 1 : -1 }
            let phase = FxMath.phase(forID: enemy.id)
            let gait = node.hasFrames ? FxStyle.framedGait(enemy.kind) : FxStyle.gait(enemy.kind)
            node.apply(FxMath.pose(distance: distance, phase: phase, gait: gait), field: field)
            node.walk(distance: distance, phase: phase)
            node.show(enemy, dt: dt, stunned: (enemy.stunUntilTick ?? Int.min) > state.tick)
            if appeared {
                fx.spawn(node)
                // Der Auftritt des Bosses (P3-4): Banner und tiefer Wellenklang.
                if node.isBoss {
                    fx.banner(BattleTexts.bossArrives, size: size)
                    audio?.play(.bossArrived)
                }
                if node.isArmored && !armorHintShown {
                    armorHintShown = true
                    fx.armorHint(node)
                }
            }
        }
        for (id, node) in enemyNodes where liveEnemies[id] == nil {
            node.removeFromParent()
            enemyNodes[id] = nil
        }
    }

    private func addNewPieces() {
        for tower in model.state.towers where towerNodes[tower.id] == nil { _ = makeTowerNode(tower) }
        for enemy in model.state.enemies where enemyNodes[enemy.id] == nil {
            let node = makeEnemyNode(enemy)
            node.position = toScene(model.sim.map.path.position(at: enemy.distance))
        }
    }

    private func makeTowerNode(_ tower: Tower) -> TowerNode {
        let node = TowerNode(tower: tower, field: field)
        node.position = toScene(tower.cell.center)
        // Weiter unten heißt weiter vorn; bleibt innerhalb der eigenen Ebene.
        node.zPosition = 1 - node.position.y / max(size.height, 1)
        towerLayer.addChild(node)
        towerNodes[tower.id] = node
        return node
    }

    private func makeEnemyNode(_ enemy: Enemy) -> EnemyNode {
        let stats = model.sim.config.enemies[enemy.kind]
        let node = EnemyNode(enemy: enemy, field: field, armored: (stats?.armor ?? 0) > 0, boss: stats?.boss != nil)
        enemyLayer.addChild(node)
        enemyNodes[enemy.id] = node
        return node
    }

    // MARK: Ereignisse

    private func play(_ event: Event) {
        if let moment = soundMoment(for: event) { audio?.play(moment) }
        switch event {
        case .towerFired(let towerID, let targets):
            guard let tower = towerNodes[towerID] else { return }
            let hit = targets.compactMap { enemyNodes[$0] }
            switch tower.kind {
            case .watch: fx.arrow(from: tower, at: hit)
            case .lightning: fx.bolt(from: tower, through: hit)
            case .spore: fx.spores(from: tower, range: model.sim.config.stats(of: .spore, level: tower.level)?.range ?? 0)
            case .bank: break
            }
        case .bankPaid(let towerID, let gold, _):
            if let tower = towerNodes[towerID] { fx.bankPaid(tower, gold: gold) }
        case .bankEmptied(let towerID):
            if let tower = towerNodes[towerID] { fx.bankEmptied(tower) }
        case .earlyCallBonus:
            // Die Gutschrift zeigt die Goldanzeige der Oberfläche.
            break
        case .enemyDamaged(let id, _):
            if let node = enemyNodes[id] { fx.hit(node) }
        case .armorAbsorbed(let id, _):
            // Klang nur, wenn auch der Funke spielt: dieselbe Grenze je Gegner.
            if let node = enemyNodes[id], fx.armor(node) { audio?.play(.armored) }
        case .enemyKilled(let id, let reward):
            // Ab hier gehört die Node dem Director, bis sie zerplatzt ist.
            if let node = enemyNodes.removeValue(forKey: id) { fx.death(node, reward: reward) }
        case .enemyLeaked(let id, _):
            if let node = enemyNodes.removeValue(forKey: id) {
                fx.leak(node, into: fortressRest, fortress: fortress, rest: fortressRest, flash: fortressHit)
            }
        case .enemySpawned(let id):
            pendingSpawns.insert(id)
        case .towerBuilt(let id):
            pendingBuilds.insert(id)
        case .towerSold(let id, let refund):
            if let node = towerNodes.removeValue(forKey: id) { fx.sell(node, refund: refund) }
        case .towerUpgraded(let id, let level):
            if let node = towerNodes[id] {
                node.showLevel(level, field: field)
                fx.upgrade(node)
            }
        case .targetModeChanged(let id, let mode):
            // Die Wahl steht auf dem Knopf; am Turm ein kurzer Hinweis, was sie heißt.
            if let node = towerNodes[id] {
                fx.hint(at: CGPoint(x: node.position.x, y: node.position.y + field * 0.9), text: BattleTexts.targetHint(mode))
            }
        case .waveStarted(let index):
            fx.banner("Welle \(index + 1) von \(model.sim.config.waves.count)", size: size)
        case .missionEnded(let won):
            // Das Ergebnis zeigt die Ergebnistafel der Oberfläche (BattleHUD).
            fx.clearBanner()
            if won { fx.victory(size: size) }
        case .commandRejected(let command, let reason):
            fx.rejected(at: position(of: command), text: BattleTexts.rejection(reason))
        case .abilityCast(let center, let impactTick):
            // Das Bollwerk steht sofort; es zeigt sich mit `barrierRaised`.
            guard let ability = model.sim.config.ability, ability.kind != .bulwark else { return }
            let seconds = Double(impactTick - model.state.tick) / Double(model.sim.config.simulation.ticksPerSecond)
            fx.strikeWarning(at: toScene(center), radius: ability.radius ?? 0, seconds: seconds,
                             moon: ability.kind == .moonMark)
        case .abilityImpact(let center, _):
            guard let ability = model.sim.config.ability else { return }
            fx.strikeImpact(at: toScene(center), radius: ability.radius ?? 0, moon: ability.kind == .moonMark)
        case .barrierRaised(let distance, _):
            raiseWall(at: distance)
        case .barrierFell:
            fx.lowerWall(named: Self.wallName)
        case .enemySlowed:
            // Verlangsamung zeigt sich über den Zustand (Farbton am Gegner).
            break
        case .bossShieldRaised:
            // Die Kuppel zeigt der Zustand; der Satz sagt, was jetzt zählt.
            fx.banner(BattleTexts.bossShield, size: size)
        case .bossSummoned(let id, _):
            if let node = enemyNodes[id] { fx.summon(node) }
        case .bossShieldDropped(let id):
            if let node = enemyNodes[id] {
                fx.hint(at: CGPoint(x: node.position.x, y: node.position.y + node.height * 1.3), text: BattleTexts.bossShieldDown)
            }
        case .shieldAbsorbed(let id):
            // Wie die Panzerung: Funke und dumpfer Treffer, mit derselben Grenze je Gegner.
            if let node = enemyNodes[id], fx.armor(node) { audio?.play(.armored) }
        }
    }

    /// Was zu hören ist. Der Sporenfunke (E2) gilt wie im Bild, wenn ein Ziel der
    /// Kette gerade verlangsamt ist; das zeigt die Node des Gegners.
    private func soundMoment(for event: Event) -> SoundMoment? {
        switch event {
        case .towerFired(let towerID, let targets):
            guard let kind = towerNodes[towerID]?.kind else { return nil }
            let combo = kind == .lightning && targets.contains { enemyNodes[$0]?.isSlowed == true }
            return .fired(kind, links: targets.count, combo: combo)
        case .towerBuilt: return .built
        case .towerSold: return .sold
        case .towerUpgraded: return .upgraded
        // Die Zielwahl hört man als Bedienton beim Tippen (`UserAction.preview`).
        case .targetModeChanged: return nil
        case .commandRejected: return .rejected
        case .enemyDamaged: return .damaged
        // Spielt `play` selbst, gedrosselt mit dem Funken.
        case .armorAbsorbed: return nil
        case .enemySlowed: return .slowed
        case .enemyKilled: return .killed
        case .enemyLeaked: return .leaked
        case .enemySpawned: return nil
        case .bossShieldRaised: return .bossShield
        case .bossSummoned: return .bossSummon
        case .bossShieldDropped: return .bossShieldDown
        // Spielt `play` selbst, gedrosselt mit dem Funken.
        case .shieldAbsorbed: return nil
        case .waveStarted(let index): return .waveStarted(index: index, count: model.sim.config.waves.count)
        case .missionEnded(let won): return .missionEnded(won: won)
        case .abilityCast:
            // Das Bollwerk steht sofort und klingt mit `barrierRaised`.
            guard let ability = model.sim.config.ability, ability.kind != .bulwark else { return nil }
            return .abilityCast
        case .abilityImpact: return .abilityImpact(moon: model.sim.config.ability?.kind == .moonMark)
        case .barrierRaised: return .wallRaised
        case .barrierFell: return .wallFell
        case .bankPaid: return .bankPaid
        // Die leere Bank wird nur grau; ein Klang dafür wäre ein Fehlalarm.
        case .bankEmptied: return nil
        case .earlyCallBonus: return .earlyCallBonus
        }
    }

    /// Wo eine Ablehnung erscheint: an der Zelle bzw. am Turm, um den es ging.
    private func position(of command: Command) -> CGPoint {
        switch command {
        case .build(_, let cell): return toScene(cell.center)
        case .sell(let id), .upgrade(let id), .setTargetMode(let id, _), .specialize(let id, _):
            return towerNodes[id]?.position ?? CGPoint(x: size.width / 2, y: size.height / 2)
        case .callNextWave: return CGPoint(x: size.width / 2, y: size.height / 2)
        case .useAbility(let point): return toScene(point)
        }
    }

    static let wallName = "barrier"

    /// Mauer quer zum Weg. Die Richtung kommt aus zwei Punkten kurz davor und
    /// dahinter, damit sie auch an einer Kurve stimmt. Eine zur Zeit (Regel).
    private func raiseWall(at distance: Double) {
        let path = model.sim.map.path
        let before = toScene(path.position(at: distance - BattleStyle.wallProbe))
        let after = toScene(path.position(at: distance + BattleStyle.wallProbe))
        fx.raiseWall(named: Self.wallName, at: toScene(path.position(at: distance)),
                     angle: atan2(after.y - before.y, after.x - before.x))
    }
}
