import OddlingsCore
import SpriteKit
import UIKit

/// Spielt die Effekte der Szene auf einer eigenen Uhr im Bildtakt (D-050).
///
/// Die Szene meldet, was passiert ist; der Director entscheidet, wie es
/// aussieht. Er liest und ändert keinen Spielzustand (Architekturregeln 2
/// und 3). Flüchtige Sprites kommen aus einem Pool, Bewegungen sind Tweens,
/// die `advance(by:)` fortschreibt. So enden Effekte auch in Tests ohne
/// Bildschirm, und kein Bild fordert neuen Speicher an
/// (docs/konzepte/fx-01-bewegung-und-effekte.md).
@MainActor
final class FxDirector {
    /// Was wie oft gespielt wurde. Für Tests und den E2E-Zähler `fx.stats`.
    struct Stats: Equatable {
        var arrows = 0, bolts = 0, combos = 0, spores = 0, hits = 0
        var deaths = 0, coins = 0, builds = 0, sells = 0, leaks = 0, spawns = 0
        var dropped = 0

        var summary: String {
            "arrows=\(arrows) bolts=\(bolts) combos=\(combos) spores=\(spores) hits=\(hits) deaths=\(deaths) "
                + "coins=\(coins) builds=\(builds) sells=\(sells) leaks=\(leaks) spawns=\(spawns) dropped=\(dropped)"
        }
    }

    enum End { case keep, remove, recycle }

    private struct Tween {
        let node: SKNode
        let key: String?
        let start: Double
        let duration: Double
        let end: End
        let update: (SKNode, Double) -> Void
        let onEnd: (() -> Void)?
    }

    /// Die Ebene der flüchtigen Effekte, in der Welt-Node der Szene.
    let layer: SKNode
    /// Wird beim Wackeln verschoben; enthält Boden, Türme, Gegner und Effekte.
    let world: SKNode
    var field: CGFloat
    /// „Bewegung reduzieren" in iOS: kein Wackeln, kein Atmen.
    var reduceMotion: Bool
    private(set) var time: Double = 0
    private(set) var stats = Stats()
    private(set) var activeSprites = 0
    private var pool: [SKSpriteNode] = []
    private var tweens: [Tween] = []
    private var trauma: Double = 0
    private var random = FxRandom(seed: 1)
    /// Wann der nächste Pfeil beim Gegner ankommt. Aufblitzen und Tod warten
    /// darauf, denn die Simulation trifft sofort.
    private var arrivals: [Int: Double] = [:]

    init(layer: SKNode, world: SKNode, field: CGFloat, reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled) {
        self.layer = layer
        self.world = world
        self.field = field
        self.reduceMotion = reduceMotion
    }

    var runningTweens: Int { tweens.count }
    /// Wann der fliegende Pfeil beim Gegner ankommt, nil ohne Pfeil.
    func arrival(for enemyID: Int) -> Double? { arrivals[enemyID] }
    var pooledSprites: Int { pool.count }

    // MARK: Uhr

    /// Ein Bild weiter. `dt` = 0 hält alles an (Pause).
    func advance(by dt: Double) {
        guard dt > 0 else { return }
        time += dt
        trauma = max(0, trauma - FxStyle.shakeDecay * dt)
        let offset = reduceMotion ? .zero : FxMath.shake(trauma: trauma, time: time, amplitude: FxStyle.shakeAmplitude)
        world.position = CGPoint(x: CGFloat(offset.x) * field, y: CGFloat(offset.y) * field)

        // In-place verdichten: kein neues Feld je Bild.
        var finished: [Tween] = []
        var write = 0
        for read in tweens.indices {
            let tween = tweens[read]
            if time >= tween.start {
                let t = tween.duration > 0 ? min(1, (time - tween.start) / tween.duration) : 1
                tween.update(tween.node, t)
                if t >= 1 {
                    finished.append(tween)
                    continue
                }
            }
            tweens[write] = tween
            write += 1
        }
        tweens.removeLast(tweens.count - write)
        // Erst danach: Ein Ende darf neue Effekte starten.
        for tween in finished { finish(tween) }
        for (id, arrival) in arrivals where arrival <= time { arrivals[id] = nil }
    }

    /// Alles abräumen (Neustart, neue Größe).
    func reset() {
        for tween in tweens {
            switch tween.end {
            case .keep: break
            case .remove: tween.node.removeFromParent()
            case .recycle: if let sprite = tween.node as? SKSpriteNode { recycle(sprite) }
            }
        }
        tweens = []
        arrivals = [:]
        trauma = 0
        world.position = .zero
    }

    private func finish(_ tween: Tween) {
        tween.onEnd?()
        switch tween.end {
        case .keep: break
        case .remove: tween.node.removeFromParent()
        case .recycle: if let sprite = tween.node as? SKSpriteNode { recycle(sprite) }
        }
    }

    /// Bewegung von `node` über `duration`, Fortschritt 0 bis 1 an `update`.
    /// Ein Schlüssel ersetzt eine laufende Bewegung gleicher Art am selben Node.
    private func animate(_ node: SKNode, key: String? = nil, delay: Double = 0, duration: Double,
                         end: End = .keep, onEnd: (() -> Void)? = nil,
                         _ update: @escaping (SKNode, Double) -> Void) {
        if let key {
            tweens.removeAll { $0.key == key && $0.node === node }
        }
        tweens.append(Tween(node: node, key: key, start: time + delay, duration: duration,
                            end: end, update: update, onEnd: onEnd))
    }

    private func after(_ delay: Double, _ action: @escaping () -> Void) {
        animate(layer, delay: delay, duration: 0, onEnd: action) { _, _ in }
    }

    private func shake(_ amount: Double) {
        trauma = min(1, trauma + amount)
    }

    // MARK: Pool

    /// Ein Sprite aus dem Pool, unsichtbar, bis seine Bewegung beginnt.
    /// Nil, wenn die Grenze erreicht ist; Zierteile entfallen schon früher.
    private func sprite(_ name: FxTextures.Name?, essential: Bool) -> SKSpriteNode? {
        let limit = essential ? FxStyle.maxSprites : Int(Double(FxStyle.maxSprites) * FxStyle.optionalShare)
        guard activeSprites < limit else {
            stats.dropped += 1
            return nil
        }
        let sprite = pool.popLast() ?? SKSpriteNode()
        sprite.texture = name.map { FxTextures.texture($0) }
        sprite.color = .white
        sprite.colorBlendFactor = name == nil ? 1 : 0
        sprite.blendMode = .alpha
        sprite.alpha = 0
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sprite.zRotation = 0
        sprite.setScale(1)
        sprite.zPosition = 0
        let side = field * 0.3
        sprite.size = CGSize(width: side, height: side)
        layer.addChild(sprite)
        activeSprites += 1
        return sprite
    }

    private func recycle(_ sprite: SKSpriteNode) {
        sprite.removeFromParent()
        pool.append(sprite)
        activeSprites -= 1
    }

    private func tinted(_ sprite: SKSpriteNode, _ color: SKColor, additive: Bool = false) {
        sprite.color = color
        sprite.colorBlendFactor = 1
        sprite.blendMode = additive ? .add : .alpha
    }

    private func vec(_ point: CGPoint) -> Vec { Vec(x: Double(point.x), y: Double(point.y)) }
    private func point(_ vec: Vec) -> CGPoint { CGPoint(x: vec.x, y: vec.y) }
    private func spread(_ range: ClosedRange<Double>) -> Double { Double.random(in: range, using: &random) }

    // MARK: Gegner

    /// Erscheinen am Wegbeginn: wächst aus einem Staubwölkchen.
    func spawn(_ enemy: EnemyNode) {
        stats.spawns += 1
        enemy.alpha = 0
        animate(enemy.reaction, key: "react", duration: FxStyle.spawnLife) { node, t in
            node.setScale(CGFloat(0.3 + 0.7 * Ease.backOut(t)))
        }
        animate(enemy, key: "fade", duration: FxStyle.spawnLife * 0.6) { node, t in node.alpha = CGFloat(t) }
        dust(at: enemy.position, count: 3, radius: 0.3, size: 0.35)
    }

    /// Treffer: helles Aufblitzen, Rückstoß gegen die Laufrichtung, kurzes
    /// Stauchen. Wartet auf einen fliegenden Pfeil.
    func hit(_ enemy: EnemyNode) {
        let start = max(time, arrivals[enemy.enemyID] ?? time)
        guard start - enemy.lastHit >= FxStyle.hitFlashGap else { return }
        enemy.lastHit = start
        stats.hits += 1
        let delay = start - time
        let knock = FxStyle.hitKnockback * field
        if let flash = enemy.flash {
            animate(flash, key: "flash", delay: delay, duration: FxStyle.hitLife) { node, t in
                node.alpha = FxStyle.hitFlashAlpha * CGFloat(1 - Ease.quadIn(t))
            }
        }
        animate(enemy.reaction, key: "react", delay: delay, duration: FxStyle.hitLife * 1.6) { [weak enemy] node, t in
            let back = CGFloat(sin(Double.pi * min(1, t * 1.4)))
            node.position = CGPoint(x: -knock * back * (enemy?.facing ?? 1), y: 0)
            node.xScale = 1 + 0.12 * back
            node.yScale = 1 - 0.12 * back
        }
    }

    /// Tod: Treffer-Halt, Stauchen, Zerplatzen in Rauch, Splittern und Münzen.
    /// Die Szene hat den Gegner schon aus ihrer Liste genommen; der Director
    /// entfernt ihn am Ende.
    func death(_ enemy: EnemyNode, reward: Int) {
        stats.deaths += 1
        enemy.hideHealth()
        let delay = max(0, (arrivals[enemy.enemyID] ?? time) - time)
        if let flash = enemy.flash {
            animate(flash, key: "flash", delay: delay, duration: FxStyle.deathLife * 0.5) { node, t in
                node.alpha = CGFloat(1 - t * 0.3)
            }
        }
        animate(enemy.reaction, key: "react", delay: delay, duration: FxStyle.deathLife) { node, t in
            if t < 0.3 {
                // Erst zusammendrücken …
                let s = Ease.quadOut(t / 0.3)
                node.xScale = CGFloat(1 + 0.3 * s)
                node.yScale = CGFloat(1 - 0.35 * s)
            } else {
                // … dann platzen.
                let s = Ease.backIn((t - 0.3) / 0.7)
                node.xScale = CGFloat(1.3 * (1 - s))
                node.yScale = CGFloat(0.65 * (1 - s) + 0.6 * s * (1 - s))
            }
        }
        animate(enemy, key: "fade", delay: delay, duration: FxStyle.deathLife, end: .remove) { node, t in
            node.alpha = CGFloat(1 - Ease.quadIn(max(0, t - 0.5) * 2))
        }
        let center = CGPoint(x: enemy.position.x, y: enemy.position.y + enemy.height * 0.45)
        let color = FxStyle.enemyColor(enemy.kind)
        after(delay + FxStyle.deathLife * 0.55) { [weak self] in
            guard let self else { return }
            self.burst(at: center, color: color)
            self.coins(at: center, count: FxStyle.coinsPerKill)
            self.label("+\(reward)", at: CGPoint(x: center.x, y: center.y + self.field * 0.4), color: FxStyle.gold)
        }
    }

    /// Durchbruch: Gegner schrumpft ins Tor, Festung bebt, Bild wackelt.
    func leak(_ enemy: EnemyNode, into gate: CGPoint, fortress: SKNode, rest: CGPoint, flash: SKNode) {
        stats.leaks += 1
        enemy.hideHealth()
        let from = enemy.position
        animate(enemy, key: "fade", duration: FxStyle.leakLife, end: .remove) { node, t in
            let s = CGFloat(Ease.quadIn(t))
            node.position = CGPoint(x: from.x + (gate.x - from.x) * s, y: from.y + (gate.y - from.y) * s)
            node.setScale(1 - 0.7 * s)
            node.alpha = 1 - s
        }
        animate(fortress, key: "quake", duration: FxStyle.leakLife * 1.4) { [field = self.field] node, t in
            let wobble = CGFloat(sin(t * Double.pi * 9) * (1 - t))
            node.position = CGPoint(x: rest.x + wobble * field * 0.08, y: rest.y)
        }
        animate(flash, key: "flash", duration: FxStyle.leakLife * 1.4) { node, t in
            node.alpha = CGFloat(1 - Ease.quadOut(t))
        }
        shake(FxStyle.shakeLeak)
    }

    // MARK: Türme

    /// Bau: Der Turm fällt auf seinen Platz, staucht beim Aufsetzen, federt
    /// nach; Staubring und Staubwolken, das Bild zuckt.
    func build(_ tower: TowerNode) {
        stats.builds += 1
        let drop = FxStyle.buildDrop * field
        let fall = 0.38
        tower.lift.alpha = 0
        tower.lift.position = CGPoint(x: 0, y: drop)
        animate(tower.lift, key: "lift", duration: FxStyle.buildLife) { node, t in
            if t < fall {
                let s = Ease.quadIn(t / fall)
                node.position = CGPoint(x: 0, y: drop * CGFloat(1 - s))
                node.alpha = CGFloat(min(1, t / fall * 2))
                node.xScale = CGFloat(0.85 + 0.15 * s)
                node.yScale = CGFloat(1.15 - 0.15 * s)
            } else {
                let s = (t - fall) / (1 - fall)
                let spring = 1 - Ease.elasticOut(s)
                node.position = .zero
                node.alpha = 1
                node.xScale = CGFloat(1 + 0.22 * spring)
                node.yScale = CGFloat(1 - 0.25 * spring)
            }
        }
        let base = tower.position
        after(FxStyle.buildLife * fall) { [weak self] in
            guard let self else { return }
            self.ring(at: CGPoint(x: base.x, y: base.y + self.field * 0.05), radius: 0.9, color: FxStyle.dust,
                      duration: 0.35, flatten: 0.38)
            self.dust(at: base, count: FxStyle.dustPuffs, radius: 0.6, size: 0.5)
            self.shake(FxStyle.shakeBuild)
        }
    }

    /// Verkauf: Turm versinkt in Staub, Münzen springen auf.
    func sell(_ tower: TowerNode, refund: Int) {
        stats.sells += 1
        animate(tower.lift, key: "lift", duration: FxStyle.sellLife) { [field = self.field] node, t in
            let s = CGFloat(Ease.quadIn(t))
            node.position = CGPoint(x: CGFloat(sin(t * 40)) * field * 0.03 * (1 - s), y: -field * 0.35 * s)
            node.yScale = 1 - 0.7 * s
            node.xScale = 1 + 0.1 * s
            node.alpha = 1 - s
        }
        animate(tower, key: "remove", duration: FxStyle.sellLife, end: .remove) { _, _ in }
        dust(at: tower.position, count: FxStyle.dustPuffs, radius: 0.55, size: 0.55)
        let top = CGPoint(x: tower.position.x, y: tower.position.y + field * 0.6)
        coins(at: top, count: FxStyle.coinsPerKill)
        label("+\(refund)", at: CGPoint(x: top.x, y: top.y + field * 0.4), color: FxStyle.gold)
    }

    /// Wachturm: Rückstoß, Pfeil im Bogen, folgt dem Ziel, Funken beim Einschlag.
    func arrow(from tower: TowerNode, at targets: [EnemyNode]) {
        recoil(tower, amount: 0.08)
        let origin = CGPoint(x: tower.position.x, y: tower.position.y + FxStyle.muzzleHeight * field)
        for target in targets {
            guard let sprite = sprite(.arrow, essential: true) else { continue }
            stats.arrows += 1
            let length = FxStyle.arrowLength * field
            sprite.size = CGSize(width: length, height: length / FxTextures.aspect(.arrow))
            sprite.zPosition = 2
            let distance = Double(hypot(target.position.x - origin.x, target.position.y - origin.y) / max(field, 1))
            let life = min(FxStyle.arrowMaxLife, max(FxStyle.arrowMinLife, distance / FxStyle.arrowSpeed))
            arrivals[target.enemyID] = max(arrivals[target.enemyID] ?? 0, time + life)
            let start = vec(origin)
            let height = FxStyle.arrowArc * distance * Double(field)
            var landed = CGPoint.zero
            animate(sprite, duration: life, end: .recycle, onEnd: { [weak self] in
                self?.sparks(at: landed, count: FxStyle.arrowHitSparks, color: FxStyle.arrowSpark, speed: 2.2, size: 0.32)
            }) { [weak target] node, t in
                let goal = target.map { CGPoint(x: $0.position.x, y: $0.position.y + $0.height * 0.45) } ?? landed
                let (position, angle) = FxMath.arc(from: start, to: Vec(x: Double(goal.x), y: Double(goal.y)),
                                                   height: height, at: t)
                node.position = CGPoint(x: position.x, y: position.y)
                node.zRotation = CGFloat(angle)
                node.alpha = 1
                landed = goal
            }
        }
    }

    /// Blitzturm: Kristall leuchtet, Blitz springt Glied für Glied. Trifft er
    /// ein verlangsamtes Ziel, sprüht der Sporenfunke (E2).
    func bolt(from tower: TowerNode, through targets: [EnemyNode]) {
        guard !targets.isEmpty else { return }
        stats.bolts += 1
        flare(tower)
        recoil(tower, amount: 0.04)
        var points = [vec(CGPoint(x: tower.position.x, y: tower.position.y + FxStyle.crystalHeight * field))]
        points += targets.map { vec(CGPoint(x: $0.position.x, y: $0.position.y + $0.height * 0.45)) }
        for index in 0..<(points.count - 1) {
            let delay = Double(index) * FxStyle.boltLinkDelay
            let zigzag = FxMath.boltPoints(from: points[index], to: points[index + 1], segments: FxStyle.boltSegments,
                                           jitter: FxStyle.boltJitter, using: &random)
            for (a, b) in zip(zigzag, zigzag.dropFirst()) {
                // Der Schein ist Zier: Unter Last bleibt der helle Kern, und Pfeile und
                // Münzen behalten ihren Platz.
                beam(from: a, to: b, width: FxStyle.boltGlowWidth, color: FxStyle.boltGlow, delay: delay, essential: false)
                beam(from: a, to: b, width: FxStyle.boltCoreWidth, color: FxStyle.boltCore, delay: delay, essential: true)
            }
            let target = targets[index]
            let hitPoint = point(points[index + 1])
            after(delay) { [weak self, weak target] in
                guard let self else { return }
                if target?.isSlowed == true {
                    self.stats.combos += 1
                    self.sparks(at: hitPoint, count: FxStyle.comboSparks, color: FxStyle.comboColor, speed: 3.2, size: 0.4)
                    self.ring(at: hitPoint, radius: 0.55, color: FxStyle.comboColor, duration: 0.25, flatten: 1, additive: true)
                } else {
                    self.sparks(at: hitPoint, count: FxStyle.boltSparks, color: FxStyle.boltGlow, speed: 2.4, size: 0.3)
                }
                self.glowPoint(at: hitPoint, color: FxStyle.boltGlow, size: 0.9, duration: 0.16)
            }
        }
    }

    /// Sporenturm: Hut staucht und federt, Ring bis zur Reichweite, Wölkchen.
    func spores(from tower: TowerNode, range: Double) {
        stats.spores += 1
        animate(tower.pulse, key: "pulse", duration: FxStyle.sporeLife) { node, t in
            let squash: Double
            if t < 0.15 {
                squash = Ease.quadOut(t / 0.15)
            } else {
                squash = 1 - Ease.elasticOut((t - 0.15) / 0.85)
            }
            node.xScale = CGFloat(1 + 0.12 * squash)
            node.yScale = CGFloat(1 - 0.16 * squash)
        }
        let center = CGPoint(x: tower.position.x, y: tower.position.y + field * 0.15)
        ring(at: center, radius: range, color: FxStyle.sporeColor, duration: FxStyle.sporeLife, flatten: 1)
        let top = CGPoint(x: tower.position.x, y: tower.position.y + field * 0.75)
        for index in 0..<FxStyle.sporePuffs {
            guard let puff = sprite(.puff, essential: false) else { break }
            tinted(puff, FxStyle.sporeColor)
            let angle = Double(index) / Double(FxStyle.sporePuffs) * 2 * Double.pi + spread(-0.25...0.25)
            let reach = range * spread(0.55...0.9) * Double(field)
            let rise = spread(0.1...0.4) * Double(field)
            let life = FxStyle.sporeLife * spread(0.9...1.3)
            let size = field * CGFloat(spread(0.35...0.55))
            animate(puff, duration: life, end: .recycle) { [field = self.field] node, t in
                let s = Ease.cubicOut(t)
                node.position = CGPoint(x: top.x + CGFloat(cos(angle) * reach * s),
                                        y: top.y + CGFloat(sin(angle) * reach * s * 0.55 + rise * s) - field * 0.3 * CGFloat(s))
                node.setScale(CGFloat(0.5 + 0.8 * s))
                (node as? SKSpriteNode)?.size = CGSize(width: size, height: size)
                node.alpha = CGFloat(0.75 * (1 - Ease.quadIn(t)))
            }
        }
    }

    // MARK: Oberfläche im Spielfeld

    func rejected(at position: CGPoint, text: String) {
        if let tile = sprite(nil, essential: true) {
            tile.color = FxStyle.reject
            tile.size = CGSize(width: field * 0.92, height: field * 0.92)
            tile.position = position
            animate(tile, duration: FxStyle.rejectLife * 1.4, end: .recycle) { node, t in
                node.alpha = CGFloat(0.55 * abs(sin(t * 3 * Double.pi)) * (1 - t))
            }
        }
        label(text, at: CGPoint(x: position.x, y: position.y + field * 0.6), color: FxStyle.reject, wiggle: true)
    }

    /// Wellenbanner: springt mit Überschwingen ein, bleibt, steigt und verblasst.
    func banner(_ text: String, size: CGSize) {
        layer.childNode(withName: "banner")?.removeFromParent()
        let node = outlinedLabel(text, fontSize: field * 0.9, color: .white)
        node.name = "banner"
        let base = CGPoint(x: size.width / 2, y: size.height * 0.72)
        node.position = base
        node.setScale(0.4)
        node.alpha = 0
        node.zPosition = 10
        layer.addChild(node)
        let total = FxStyle.bannerIn + FxStyle.bannerHold + FxStyle.bannerOut
        let inShare = FxStyle.bannerIn / total, outStart = 1 - FxStyle.bannerOut / total
        animate(node, duration: total, end: .remove) { [field = self.field] node, t in
            if t < inShare {
                let s = t / inShare
                node.setScale(CGFloat(0.4 + 0.6 * Ease.backOut(s)))
                node.alpha = CGFloat(min(1, s * 2))
            } else if t < outStart {
                node.setScale(1)
                node.alpha = 1
            } else {
                let s = (t - outStart) / (1 - outStart)
                node.position = CGPoint(x: base.x, y: base.y + field * 0.5 * CGFloat(Ease.quadIn(s)))
                node.alpha = CGFloat(1 - s)
            }
        }
    }

    func clearBanner() { layer.childNode(withName: "banner")?.removeFromParent() }

    /// Sieg: Konfetti von oben über die ganze Breite.
    func victory(size: CGSize) {
        for index in 0..<FxStyle.confetti {
            guard let piece = sprite(.confetti, essential: false) else { break }
            tinted(piece, FxStyle.confettiColors[index % FxStyle.confettiColors.count])
            piece.size = CGSize(width: field * 0.22, height: field * 0.15)
            piece.zPosition = 9
            let x = spread(0...1) * Double(size.width)
            let fall = Double(size.height) * spread(0.6...1.0)
            let sway = spread(0.2...0.5) * Double(field)
            let spin = spread(4...9)
            let phase = spread(0...(2 * Double.pi))
            let life = FxStyle.confettiLife * spread(0.8...1.2)
            let top = Double(size.height) + Double(field)
            animate(piece, delay: spread(0...0.35), duration: life, end: .recycle) { node, t in
                node.position = CGPoint(x: x + sin(t * 9 + phase) * sway, y: top - fall * t)
                node.zRotation = CGFloat(t * spin + phase)
                node.xScale = CGFloat(abs(cos(t * spin * 1.7 + phase)))
                node.alpha = CGFloat(t > 0.8 ? (1 - t) * 5 : 1)
            }
        }
    }

    // MARK: Bausteine

    private func recoil(_ tower: TowerNode, amount: Double) {
        animate(tower.pulse, key: "pulse", duration: FxStyle.recoilLife) { node, t in
            let s = sin(Double.pi * min(1, t * 1.6)) * (1 - t)
            node.yScale = CGFloat(1 - amount * s)
            node.xScale = CGFloat(1 + amount * 0.6 * s)
        }
    }

    private func flare(_ tower: TowerNode) {
        animate(tower, key: "flare", duration: FxStyle.boltLife * 1.5) { node, t in
            (node as? TowerNode)?.flare = CGFloat(1 - Ease.quadOut(t))
        }
    }

    /// Ein gerades Stück Strahl von `a` nach `b` (Glühen oder Kern des Blitzes).
    private func beam(from a: Vec, to b: Vec, width: CGFloat, color: SKColor, delay: Double, essential: Bool) {
        guard let segment = sprite(.bolt, essential: essential) else { return }
        tinted(segment, color, additive: true)
        segment.anchorPoint = CGPoint(x: 0, y: 0.5)
        segment.position = point(a)
        segment.zRotation = CGFloat((b - a).angle)
        segment.size = CGSize(width: CGFloat((b - a).length) + width * field * 0.3, height: width * field)
        segment.zPosition = 3
        animate(segment, delay: delay, duration: FxStyle.boltLife, end: .recycle) { node, t in
            // Flackern statt gleichmäßig auszublenden: Blitze zucken.
            let flicker = 0.75 + 0.25 * sin(t * 50)
            node.alpha = CGFloat(pow(1 - t, 1.4) * flicker)
        }
    }

    private func glowPoint(at position: CGPoint, color: SKColor, size: CGFloat, duration: Double) {
        guard let glow = sprite(.glow, essential: false) else { return }
        tinted(glow, color, additive: true)
        glow.position = position
        glow.size = CGSize(width: field * size, height: field * size)
        animate(glow, duration: duration, end: .recycle) { node, t in
            node.setScale(CGFloat(0.6 + 0.6 * Ease.quadOut(t)))
            node.alpha = CGFloat(1 - t)
        }
    }

    /// Funken in alle Richtungen, in Flugrichtung gestreckt, mit Schwerkraft.
    private func sparks(at position: CGPoint, count: Int, color: SKColor, speed: Double, size: CGFloat) {
        for _ in 0..<count {
            guard let spark = sprite(.spark, essential: false) else { return }
            tinted(spark, color, additive: true)
            let length = field * size * CGFloat(spread(0.7...1.2))
            spark.size = CGSize(width: length, height: length / FxTextures.aspect(.spark))
            spark.zPosition = 4
            let angle = spread(0...(2 * Double.pi))
            let velocity = Vec(x: cos(angle), y: sin(angle) + 0.4) * (speed * spread(0.6...1.2) * Double(field))
            let life = spread(0.16...0.28)
            let start = vec(position)
            let gravity = 7 * Double(field)
            animate(spark, duration: life, end: .recycle) { node, t in
                let time = t * life
                node.position = CGPoint(x: 0, y: 0) + FxMath.ballistic(start: start, velocity: velocity, gravity: gravity, at: time)
                let moving = velocity + Vec(x: 0, y: -gravity * time)
                node.zRotation = CGFloat(moving.angle)
                node.xScale = CGFloat(1 - 0.6 * t)
                node.alpha = CGFloat(1 - Ease.quadIn(t))
            }
        }
    }

    /// Flacher Ring am Boden (Staub, Druckwelle) oder runder Ring (Sporen).
    private func ring(at position: CGPoint, radius: Double, color: SKColor, duration: Double,
                      flatten: CGFloat, additive: Bool = false) {
        guard let ring = sprite(.ring, essential: true) else { return }
        tinted(ring, color, additive: additive)
        ring.position = position
        ring.zPosition = -1
        let diameter = CGFloat(radius * 2) * field
        animate(ring, duration: duration, end: .recycle) { node, t in
            let s = CGFloat(0.25 + 0.75 * Ease.cubicOut(t))
            (node as? SKSpriteNode)?.size = CGSize(width: diameter * s, height: diameter * s * flatten)
            node.alpha = CGFloat(0.85 * (1 - Ease.quadIn(t)))
        }
    }

    /// Staubwolken am Boden, die zur Seite treiben und aufsteigen.
    private func dust(at position: CGPoint, count: Int, radius: Double, size: Double) {
        for index in 0..<count {
            guard let puff = sprite(.puff, essential: false) else { return }
            tinted(puff, FxStyle.dust)
            let angle = Double(index) / Double(max(count, 1)) * 2 * Double.pi + spread(-0.3...0.3)
            let reach = radius * Double(field) * spread(0.7...1.1)
            let side = field * CGFloat(size * spread(0.8...1.2))
            puff.size = CGSize(width: side, height: side)
            let life = spread(0.35...0.55)
            animate(puff, duration: life, end: .recycle) { [field = self.field] node, t in
                let s = Ease.cubicOut(t)
                node.position = CGPoint(x: position.x + CGFloat(cos(angle) * reach * s),
                                        y: position.y + CGFloat(sin(angle) * reach * s * 0.35) + field * 0.25 * CGFloat(s))
                node.setScale(CGFloat(0.6 + 0.7 * s))
                node.alpha = CGFloat(0.8 * (1 - Ease.quadIn(t)))
            }
        }
    }

    /// Zerplatzen: Rauch steigt auf, Splitter in der Farbe des Gegners fliegen.
    private func burst(at position: CGPoint, color: SKColor) {
        glowPoint(at: position, color: .white, size: 1.1, duration: 0.14)
        for _ in 0..<FxStyle.deathSmoke {
            guard let smoke = sprite(.puff, essential: false) else { break }
            tinted(smoke, SKColor(white: 0.92, alpha: 1))
            let side = field * CGFloat(spread(0.35...0.6))
            smoke.size = CGSize(width: side, height: side)
            let drift = Vec(x: spread(-0.5...0.5), y: spread(0.3...0.8)) * Double(field)
            let life = spread(0.4...0.6)
            animate(smoke, duration: life, end: .recycle) { node, t in
                let s = Ease.cubicOut(t)
                node.position = CGPoint(x: position.x + CGFloat(drift.x * s), y: position.y + CGFloat(drift.y * s))
                node.setScale(CGFloat(0.6 + 0.9 * s))
                node.alpha = CGFloat(0.85 * (1 - Ease.quadIn(t)))
            }
        }
        for _ in 0..<FxStyle.deathChunks {
            guard let chunk = sprite(.confetti, essential: false) else { break }
            tinted(chunk, color)
            chunk.size = CGSize(width: field * 0.16, height: field * 0.12)
            chunk.zPosition = 1
            let angle = spread(0.15...(Double.pi - 0.15))
            let velocity = Vec(x: cos(angle), y: sin(angle)) * (spread(1.6...3.0) * Double(field))
            let spin = spread(-14...14)
            let life = spread(0.45...0.65)
            let start = vec(position)
            let gravity = 9 * Double(field)
            animate(chunk, duration: life, end: .recycle) { node, t in
                node.position = CGPoint(x: 0, y: 0) + FxMath.ballistic(start: start, velocity: velocity, gravity: gravity, at: t * life)
                node.zRotation = CGFloat(spin * t)
                node.alpha = CGFloat(t > 0.7 ? (1 - t) / 0.3 : 1)
            }
        }
    }

    /// Münzen springen heraus, drehen sich und fallen.
    private func coins(at position: CGPoint, count: Int) {
        for index in 0..<count {
            guard let coin = sprite(.coin, essential: true) else { return }
            stats.coins += 1
            let side = FxStyle.coinSize * field
            coin.size = CGSize(width: side, height: side)
            coin.zPosition = 5
            let side0 = Double(index) - Double(count - 1) / 2
            let velocity = Vec(x: side0 * 0.9 + spread(-0.3...0.3), y: spread(2.6...3.4)) * Double(field)
            let spin = spread(10...16)
            let life = FxStyle.coinLife * spread(0.9...1.1)
            let start = vec(position)
            let gravity = 10 * Double(field)
            animate(coin, delay: Double(index) * 0.03, duration: life, end: .recycle) { node, t in
                node.position = CGPoint(x: 0, y: 0) + FxMath.ballistic(start: start, velocity: velocity, gravity: gravity, at: t * life)
                // Drehen um die Hochachse: Breite schwingt, nie ganz auf null.
                node.xScale = CGFloat(max(0.15, abs(cos(t * spin))))
                node.alpha = CGFloat(t > 0.7 ? (1 - t) / 0.3 : 1)
            }
        }
    }

    /// Zahl oder Hinweis, springt auf und steigt.
    private func label(_ text: String, at position: CGPoint, color: SKColor, wiggle: Bool = false) {
        let node = outlinedLabel(text, fontSize: field * 0.42, color: color)
        node.position = position
        node.setScale(0.3)
        node.alpha = 0
        node.zPosition = 8
        layer.addChild(node)
        animate(node, duration: FxStyle.floatLife, end: .remove) { [field = self.field] node, t in
            let pop = t < 0.25 ? Ease.backOut(t / 0.25) : 1
            node.setScale(CGFloat(0.3 + 0.7 * pop))
            let shiver = wiggle ? CGFloat(sin(t * 50) * (1 - t)) * field * 0.08 : 0
            node.position = CGPoint(x: position.x + shiver, y: position.y + field * 0.6 * CGFloat(Ease.cubicOut(t)))
            node.alpha = CGFloat(t > 0.65 ? (1 - t) / 0.35 : 1)
        }
    }

    /// Schrift mit dunkler Kontur, wie die gemalten Figuren: lesbar auf jedem Boden.
    private func outlinedLabel(_ text: String, fontSize: CGFloat, color: SKColor) -> SKNode {
        let node = SKNode()
        let offsets: [CGPoint] = [CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1), CGPoint(x: -1, y: 1),
                                  CGPoint(x: 1, y: 1), CGPoint(x: 0, y: -1.6)]
        let width = max(1.2, fontSize * 0.07)
        for offset in offsets {
            let back = SKLabelNode(text: text)
            back.fontName = BattleStyle.font
            back.fontSize = fontSize
            back.fontColor = SKColor(red: 0x22 / 255, green: 0x16 / 255, blue: 0x0F / 255, alpha: 1)
            back.verticalAlignmentMode = .center
            back.position = CGPoint(x: offset.x * width, y: offset.y * width)
            node.addChild(back)
        }
        let front = SKLabelNode(text: text)
        front.fontName = BattleStyle.font
        front.fontSize = fontSize
        front.fontColor = color
        front.verticalAlignmentMode = .center
        node.addChild(front)
        return node
    }
}

private extension CGPoint {
    static func + (point: CGPoint, vec: Vec) -> CGPoint {
        CGPoint(x: point.x + CGFloat(vec.x), y: point.y + CGFloat(vec.y))
    }
}
