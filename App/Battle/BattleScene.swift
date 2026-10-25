import OddlingsCore
import SpriteKit

/// Zeigt, was die Simulation tut (WP-11). Die Szene liest Zustand und
/// Ereignisse und ändert nichts davon (Architekturregel 2). Alle Effekte hängen
/// an Ereignissen (Architekturregel 3); was dauerhaft sichtbar ist (Türme,
/// Gegner, Lebensbalken, Verlangsamung), folgt dem Zustand.
@MainActor
final class BattleScene: SKScene {
    let model: BattleModel
    private(set) var towerNodes: [Int: SKNode] = [:]
    private(set) var enemyNodes: [Int: EnemyNode] = [:]

    private let ground = SKNode()
    private let towerLayer = SKNode()
    private let enemyLayer = SKNode()
    private let effectLayer = SKNode()
    private let fortress = SKShapeNode()
    private let fortressHit = SKShapeNode()
    private var field: CGFloat = 1
    private var origin: CGPoint = .zero
    private var lastTime: TimeInterval?

    init(model: BattleModel) {
        self.model = model
        super.init(size: CGSize(width: 844, height: 390))
        scaleMode = .resizeFill
        backgroundColor = BattleStyle.background
        for (layer, z) in [(ground, 0), (towerLayer, 10), (enemyLayer, 20), (effectLayer, 30)] {
            layer.zPosition = CGFloat(z)
            addChild(layer)
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
    }

    /// Ein Bild: fällige Schritte rechnen, Effekte auslösen, Zustand zeigen.
    /// Eigene Methode, damit Tests ohne Bildschirm Bilder erzeugen können.
    func frame(after frameTime: TimeInterval) {
        let events = model.advance(by: frameTime)
        // Effekte vor dem Abgleich, solange getötete Gegner noch eine Node haben.
        for event in events { play(event) }
        sync()
    }

    func restart() {
        model.restart()
        for node in towerNodes.values { node.removeFromParent() }
        for node in enemyNodes.values { node.removeFromParent() }
        towerNodes = [:]
        enemyNodes = [:]
        effectLayer.removeAllChildren()
        sync()
    }

    // MARK: Karte

    /// Felder → Punkte. Die Karte zählt y von oben, SpriteKit von unten.
    private func toScene(_ point: Point) -> CGPoint {
        CGPoint(x: origin.x + CGFloat(point.x) * field,
                y: origin.y + (CGFloat(model.sim.map.height) - CGFloat(point.y)) * field)
    }

    private func layoutMap() {
        guard size.width > 0, size.height > 0 else { return }
        let map = model.sim.map
        let width = CGFloat(map.width), height = CGFloat(map.height)
        field = min(size.width / width, size.height / height)
        origin = CGPoint(x: (size.width - field * width) / 2, y: (size.height - field * height) / 2)

        ground.removeAllChildren()
        let inset = BattleStyle.buildZoneInset * field
        for cell in map.buildableCells {
            let tile = SKSpriteNode(color: BattleStyle.buildZone,
                                    size: CGSize(width: field - 2 * inset, height: field - 2 * inset))
            tile.position = toScene(cell.center)
            ground.addChild(tile)
        }
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

        // Die Festung sitzt, wo der Weg die Karte verlässt.
        let end = map.path.points[map.path.points.count - 1]
        let gate = Point(x: min(end.x, Double(map.width)), y: end.y)
        fortress.path = CGPath(roundedRect: CGRect(x: -field * 0.6, y: -field * 0.9, width: field * 1.2, height: field * 1.8),
                               cornerWidth: field * 0.2, cornerHeight: field * 0.2, transform: nil)
        fortress.fillColor = BattleStyle.fortress
        fortress.strokeColor = .black
        fortress.position = toScene(gate)
        fortressHit.path = fortress.path
        fortressHit.fillColor = BattleStyle.leak
        fortressHit.strokeColor = .clear
        fortressHit.alpha = 0
        if fortressHit.parent == nil { fortress.addChild(fortressHit) }
        fortress.removeFromParent()
        ground.addChild(fortress)

        // Größen hängen am Feld: bei neuer Größe alles neu aufbauen.
        for node in towerNodes.values { node.removeFromParent() }
        for node in enemyNodes.values { node.removeFromParent() }
        towerNodes = [:]
        enemyNodes = [:]
        sync()
    }

    // MARK: Zustand

    /// Gleicht Nodes mit dem Zustand ab. Danach gibt es für jeden Turm und
    /// jeden Gegner genau eine Node (Test in BattleSceneTests).
    func sync() {
        let state = model.state
        var liveTowers: [Int: Bool] = [:]
        for tower in state.towers {
            liveTowers[tower.id] = true
            guard towerNodes[tower.id] == nil else { continue }
            let node = BattleSprites.tower(tower.kind, field: field)
            node.position = toScene(tower.cell.center)
            // Weiter unten heißt weiter vorn; bleibt innerhalb der eigenen Ebene.
            node.zPosition = 1 - node.position.y / max(size.height, 1)
            towerLayer.addChild(node)
            towerNodes[tower.id] = node
            node.setScale(0.6)
            node.run(.scale(to: 1, duration: BattleStyle.hitFlash * 2))
        }
        for (id, node) in towerNodes where liveTowers[id] == nil {
            node.removeFromParent()
            towerNodes[id] = nil
        }

        var before: [Int: Double] = [:]
        for enemy in model.previous.enemies { before[enemy.id] = enemy.distance }
        let t = model.interpolation
        var liveEnemies: [Int: Bool] = [:]
        for enemy in state.enemies {
            liveEnemies[enemy.id] = true
            let node: EnemyNode
            if let existing = enemyNodes[enemy.id] {
                node = existing
            } else {
                node = EnemyNode(enemy: enemy, field: field)
                enemyLayer.addChild(node)
                enemyNodes[enemy.id] = node
            }
            let from = before[enemy.id] ?? enemy.distance
            let distance = from + (enemy.distance - from) * t
            node.position = toScene(model.sim.map.path.position(at: distance))
            node.zPosition = 1 - node.position.y / max(size.height, 1)
            node.show(enemy)
        }
        for (id, node) in enemyNodes where liveEnemies[id] == nil {
            node.removeFromParent()
            enemyNodes[id] = nil
        }
    }

    // MARK: Ereignisse

    private func play(_ event: Event) {
        switch event {
        case .towerFired(let towerID, let targets):
            guard let tower = model.state.towers.first(where: { $0.id == towerID }),
                  let origin = towerNodes[towerID]?.position else { return }
            let points = targets.compactMap { enemyNodes[$0]?.position }
            switch tower.kind {
            case .watch: shot(from: origin, to: points)
            case .lightning: bolt(from: origin, through: points)
            case .spore: pulse(at: origin, range: model.sim.config.towers[.spore]?.range ?? 0)
            }
        case .enemyDamaged(let id, _):
            enemyNodes[id]?.flash()
        case .enemyKilled(let id, let reward):
            guard let position = enemyNodes[id]?.position else { return }
            pop(at: position)
            float("+\(reward)", at: position, color: BattleStyle.gold)
        case .enemyLeaked:
            fortressHit.removeAllActions()
            fortressHit.alpha = 1
            fortressHit.run(.fadeOut(withDuration: BattleStyle.hitFlash * 4))
        case .waveStarted(let index):
            banner("Welle \(index + 1) von \(model.sim.config.waves.count)")
        case .missionEnded(let won):
            banner(won ? "Sieg" : "Niederlage", stays: true)
        case .towerBuilt, .towerSold, .commandRejected, .enemySpawned, .enemySlowed:
            // Bauen zeigt sich über den Zustand (Aufbau-Animation in `sync`),
            // Verlangsamung als Markierung am Gegner, Ablehnung kommt mit WP-12.
            break
        }
    }

    private func fade(_ node: SKNode, after life: TimeInterval) {
        effectLayer.addChild(node)
        node.run(.sequence([.fadeOut(withDuration: life), .removeFromParent()]))
    }

    private func shot(from origin: CGPoint, to points: [CGPoint]) {
        for target in points {
            let line = CGMutablePath()
            line.move(to: CGPoint(x: origin.x, y: origin.y + field * 0.6))
            line.addLine(to: CGPoint(x: target.x, y: target.y + field * 0.3))
            let node = SKShapeNode(path: line)
            node.strokeColor = BattleStyle.arrow
            node.lineWidth = max(1.5, field * 0.04)
            fade(node, after: BattleStyle.shotLife)
        }
    }

    private func bolt(from origin: CGPoint, through points: [CGPoint]) {
        guard !points.isEmpty else { return }
        let line = CGMutablePath()
        line.move(to: CGPoint(x: origin.x, y: origin.y + field * 0.8))
        for point in points { line.addLine(to: CGPoint(x: point.x, y: point.y + field * 0.35)) }
        let node = SKShapeNode(path: line)
        node.strokeColor = BattleStyle.bolt
        node.lineWidth = max(2, field * 0.06)
        node.glowWidth = field * 0.08
        fade(node, after: BattleStyle.boltLife)
    }

    private func pulse(at origin: CGPoint, range: Double) {
        let radius = CGFloat(range) * field
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = BattleStyle.sporeCloud
        node.strokeColor = .clear
        node.position = origin
        node.setScale(0.3)
        node.run(.scale(to: 1, duration: BattleStyle.pulseLife))
        fade(node, after: BattleStyle.pulseLife)
    }

    private func pop(at position: CGPoint) {
        let node = SKShapeNode(circleOfRadius: field * 0.3)
        node.strokeColor = .white
        node.lineWidth = 2
        node.position = CGPoint(x: position.x, y: position.y + field * 0.3)
        node.run(.scale(to: 1.8, duration: BattleStyle.deathLife))
        fade(node, after: BattleStyle.deathLife)
    }

    private func float(_ text: String, at position: CGPoint, color: SKColor) {
        let label = SKLabelNode(text: text)
        label.fontName = BattleStyle.font
        label.fontSize = field * 0.4
        label.fontColor = color
        label.position = CGPoint(x: position.x, y: position.y + field * 0.8)
        label.run(.moveBy(x: 0, y: field * 0.8, duration: BattleStyle.floatLife))
        fade(label, after: BattleStyle.floatLife)
    }

    private func banner(_ text: String, stays: Bool = false) {
        effectLayer.childNode(withName: "banner")?.removeFromParent()
        let label = SKLabelNode(text: text)
        label.name = "banner"
        label.fontName = BattleStyle.font
        label.fontSize = field * 0.9
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        if stays {
            effectLayer.addChild(label)
        } else {
            fade(label, after: BattleStyle.bannerLife)
        }
    }
}
