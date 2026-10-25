import SpriteKit

/// Wegwerfszene für WP-01. Sie beantwortet nur eine Frage: Hält SpriteKit mit
/// einem SwiftUI-HUD darüber 60 Bilder/s, wenn so viel los ist wie im Finale
/// von Mission 1? Die Logik hier ist bewusst keine Spiellogik und wandert
/// nicht in OddlingsCore.
@MainActor
final class SpikeScene: SKScene {
    private let map: SpikeMap
    private let path: SpikePath
    private let stats: SpikeStats

    private struct Walker {
        let node: SKSpriteNode
        var distance: Double
        let speed: Double
    }

    private var walkers: [Walker] = []
    private var fieldSize: CGFloat = 1
    private var origin: CGPoint = .zero
    private let pathNode = SKShapeNode()

    private var lastTime: TimeInterval?
    private var frameCount = 0
    private var periodStart: TimeInterval = 0
    private var worstFrame: TimeInterval = 0
    private var lightningClock: TimeInterval = 0

    // Etwa so viele Blitzketten je Sekunde wie zehn Blitztürme im Takt von 1,2 s
    // mit Reserve: 30.
    private let lightningPerSecond: Double = 30
    private let lightningLife: TimeInterval = 0.15

    init(map: SpikeMap, stats: SpikeStats) {
        self.map = map
        self.path = SpikePath(points: map.points)
        self.stats = stats
        super.init(size: CGSize(width: 844, height: 390))
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.18, green: 0.32, blue: 0.20, alpha: 1)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("nicht benutzt") }

    override func didMove(to view: SKView) {
        pathNode.strokeColor = SKColor(red: 0.62, green: 0.50, blue: 0.33, alpha: 1)
        pathNode.lineJoin = .round
        pathNode.lineCap = .round
        pathNode.zPosition = 0
        addChild(pathNode)
        layoutMap()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutMap()
    }

    /// Felder → Punkte. Die Karte füllt die Höhe oder Breite, je nachdem, was
    /// zuerst anstößt; y wird gespiegelt, weil die Karte von oben zählt und
    /// SpriteKit von unten.
    private func layoutMap() {
        guard size.width > 0, size.height > 0 else { return }
        let mapWidth = CGFloat(map.width), mapHeight = CGFloat(map.height)
        fieldSize = min(size.width / mapWidth, size.height / mapHeight)
        origin = CGPoint(
            x: (size.width - fieldSize * mapWidth) / 2,
            y: (size.height - fieldSize * mapHeight) / 2
        )
        let cg = CGMutablePath()
        for (i, p) in path.points.enumerated() {
            if i == 0 { cg.move(to: toScene(p)) } else { cg.addLine(to: toScene(p)) }
        }
        pathNode.path = cg
        pathNode.lineWidth = fieldSize * 0.8
        for w in walkers { w.node.size = walkerSize }
    }

    private func toScene(_ field: CGPoint) -> CGPoint {
        CGPoint(x: origin.x + field.x * fieldSize,
                y: origin.y + (CGFloat(map.height) - field.y) * fieldSize)
    }

    private var walkerSize: CGSize { CGSize(width: fieldSize * 0.35, height: fieldSize * 0.35) }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime.map { currentTime - $0 } ?? 0
        lastTime = currentTime
        measure(dt: dt, now: currentTime)
        adjustWalkerCount()

        let step = min(dt, 1.0 / 15)
        for i in walkers.indices {
            walkers[i].distance += walkers[i].speed * step
            if walkers[i].distance >= path.length { walkers[i].distance -= path.length }
            walkers[i].node.position = toScene(path.position(at: walkers[i].distance))
        }

        if stats.lightningEnabled {
            lightningClock += step
            let interval = 1.0 / lightningPerSecond
            while lightningClock >= interval {
                lightningClock -= interval
                spawnLightning()
            }
        }
    }

    private func adjustWalkerCount() {
        let target = stats.targetSpriteCount
        while walkers.count < target {
            let node = SKSpriteNode(color: walkers.count % 3 == 0 ? .systemTeal : .systemRed, size: walkerSize)
            node.zPosition = 1
            addChild(node)
            // Gleichmäßig verteilt, zwei Geschwindigkeiten wie Plünderer und Flitzer.
            let distance = path.length * Double(walkers.count % target) / Double(target)
            walkers.append(Walker(node: node, distance: distance, speed: walkers.count % 3 == 0 ? 2.2 : 1.0))
        }
        while walkers.count > target {
            walkers.removeLast().node.removeFromParent()
        }
    }

    /// Eine Kette über fünf benachbarte Figuren, wie ein voll ausgeschöpfter
    /// Blitzturm (vier Sprünge). SKShapeNode ist der langsamste Weg, Linien zu
    /// zeichnen; besteht er die Probe, besteht jeder schnellere sie auch.
    private func spawnLightning() {
        guard walkers.count >= 5 else { return }
        let start = Int.random(in: 0..<(walkers.count - 4))
        let cg = CGMutablePath()
        cg.move(to: walkers[start].node.position)
        for j in 1...4 { cg.addLine(to: walkers[start + j].node.position) }
        let bolt = SKShapeNode(path: cg)
        bolt.strokeColor = SKColor(red: 0.75, green: 0.85, blue: 1, alpha: 1)
        bolt.lineWidth = max(2, fieldSize * 0.06)
        bolt.glowWidth = fieldSize * 0.08
        bolt.zPosition = 2
        addChild(bolt)
        bolt.run(.sequence([.fadeOut(withDuration: lightningLife), .removeFromParent()]))
    }

    private func measure(dt: TimeInterval, now: TimeInterval) {
        guard dt > 0 else { periodStart = now; return }
        frameCount += 1
        worstFrame = max(worstFrame, dt)
        let elapsed = now - periodStart
        if elapsed >= 0.5 {
            stats.averageFPS = Double(frameCount) / elapsed
            stats.worstFrameMS = worstFrame * 1000
            stats.spriteCount = walkers.count
            stats.updates += 1
            frameCount = 0
            worstFrame = 0
            periodStart = now
        }
    }
}
