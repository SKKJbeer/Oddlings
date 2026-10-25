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
        // Wer in diesem Takt erscheint, kann im selben Takt schon getroffen
        // werden: Seine Node muss stehen, bevor der Pfeil sie sucht.
        addNewEnemies()
        // Effekte vor dem Abgleich, solange getötete Gegner noch eine Node haben.
        for event in events { play(event) }
        sync(dt: fxTime)
        fx.advance(by: fxTime)
        controller?.afterFrame()
        showSelection()
    }

    func restart() {
        model.restart()
        fx.reset()
        clearPieces()
        controller?.restart()
        sync(dt: 0)
        showSelection()
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
        controller?.tap(layout.cell(atScene: touch.location(in: self)))
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
        fortress.path = CGPath(roundedRect: CGRect(x: -field * 0.6, y: -field * 0.9, width: field * 1.2, height: field * 1.8),
                               cornerWidth: field * 0.2, cornerHeight: field * 0.2, transform: nil)
        fortress.removeAllChildren()
        if let picture = BattleSprites.fortress(field: field) {
            // Das Bild ersetzt die Form; die Form bleibt als unsichtbarer Träger
            // für das Aufblitzen bei einem Durchbruch.
            fortress.fillColor = .clear
            fortress.strokeColor = .clear
            // Das Tor sitzt auf der Kartenkante; das Bild rückt so weit herein,
            // dass die Festung ganz zu sehen ist.
            picture.position = CGPoint(x: -BattleStyle.fortressSpriteSide * field * 0.3, y: -field * 0.9)
            fortress.addChild(picture)
        } else {
            fortress.fillColor = BattleStyle.fortress
            fortress.strokeColor = .black
        }
        fortress.position = toScene(gate)
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
        sync(dt: 0)
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
            let node: TowerNode
            if let existing = towerNodes[tower.id] {
                node = existing
            } else {
                node = TowerNode(tower: tower, field: field)
                node.position = toScene(tower.cell.center)
                // Weiter unten heißt weiter vorn; bleibt innerhalb der eigenen Ebene.
                node.zPosition = 1 - node.position.y / max(size.height, 1)
                towerLayer.addChild(node)
                towerNodes[tower.id] = node
                if pendingBuilds.remove(tower.id) != nil { fx.build(node) }
            }
            node.idle(time: fx.time, still: fx.reduceMotion)
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
            node.apply(FxMath.pose(distance: distance, phase: FxMath.phase(forID: enemy.id),
                                   gait: FxStyle.gait(enemy.kind)), field: field)
            node.show(enemy, dt: dt)
            if appeared { fx.spawn(node) }
        }
        for (id, node) in enemyNodes where liveEnemies[id] == nil {
            node.removeFromParent()
            enemyNodes[id] = nil
        }
    }

    private func addNewEnemies() {
        for enemy in model.state.enemies where enemyNodes[enemy.id] == nil {
            let node = makeEnemyNode(enemy)
            node.position = toScene(model.sim.map.path.position(at: enemy.distance))
        }
    }

    private func makeEnemyNode(_ enemy: Enemy) -> EnemyNode {
        let node = EnemyNode(enemy: enemy, field: field)
        enemyLayer.addChild(node)
        enemyNodes[enemy.id] = node
        return node
    }

    // MARK: Ereignisse

    private func play(_ event: Event) {
        switch event {
        case .towerFired(let towerID, let targets):
            guard let tower = towerNodes[towerID] else { return }
            let hit = targets.compactMap { enemyNodes[$0] }
            switch tower.kind {
            case .watch: fx.arrow(from: tower, at: hit)
            case .lightning: fx.bolt(from: tower, through: hit)
            case .spore: fx.spores(from: tower, range: model.sim.config.towers[.spore]?.range ?? 0)
            }
        case .enemyDamaged(let id, _):
            if let node = enemyNodes[id] { fx.hit(node) }
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
        case .waveStarted(let index):
            fx.banner("Welle \(index + 1) von \(model.sim.config.waves.count)", size: size)
        case .missionEnded(let won):
            // Das Ergebnis zeigt die Ergebnistafel der Oberfläche (BattleHUD).
            fx.clearBanner()
            if won { fx.victory(size: size) }
        case .commandRejected(let command, let reason):
            fx.rejected(at: position(of: command), text: BattleTexts.rejection(reason))
        case .enemySlowed:
            // Verlangsamung zeigt sich über den Zustand (Farbton am Gegner).
            break
        }
    }

    /// Wo eine Ablehnung erscheint: an der Zelle bzw. am Turm, um den es ging.
    private func position(of command: Command) -> CGPoint {
        switch command {
        case .build(_, let cell): return toScene(cell.center)
        case .sell(let id): return towerNodes[id]?.position ?? CGPoint(x: size.width / 2, y: size.height / 2)
        case .callNextWave: return CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }
}
