import OddlingsCore
import SpriteKit
import UIKit

/// Bilder nach den Namen aus dem Asset-Vertrag (tower_watch, enemy_raider, …).
/// Liegt ein Bild im Katalog, wird es benutzt, sonst eine Platzhalterform.
/// So ist der Tausch gegen echte Grafik nur ein neuer Katalog, kein Codeumbau.
@MainActor
enum BattleSprites {
    /// Wappenschild, Spitze unten, mittig um den Nullpunkt; `size` ist die Höhe.
    static func shieldPath(size: CGFloat) -> CGPath {
        let w = size * 0.8, h = size
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -w / 2, y: h / 2))
        path.addLine(to: CGPoint(x: w / 2, y: h / 2))
        path.addLine(to: CGPoint(x: w / 2, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: -h / 2), control: CGPoint(x: w / 2, y: -h * 0.3))
        path.addQuadCurve(to: CGPoint(x: -w / 2, y: 0), control: CGPoint(x: -w / 2, y: -h * 0.3))
        path.closeSubpath()
        return path
    }

    static func towerName(_ kind: TowerKind) -> String { "tower_\(kind.rawValue)" }
    /// Stufe 2 hat ein eigenes Bild (`tower_watch_2`); Stufe 1 den Grundnamen.
    static func towerName(_ kind: TowerKind, level: Int) -> String {
        level >= 2 ? "tower_\(kind.rawValue)_\(level)" : towerName(kind)
    }
    static func enemyName(_ kind: EnemyKind) -> String { "enemy_\(kind.rawValue)" }
    static let fortressName = "fortress"
    /// `mission-01` → `map_mission01_ground`.
    static func groundName(missionID: String) -> String {
        "map_\(missionID.replacingOccurrences(of: "-", with: ""))_ground"
    }

    static func texture(named name: String) -> SKTexture? {
        UIImage(named: name) == nil ? nil : SKTexture(imageNamed: name)
    }

    /// Turm, Fußpunkt auf dem Ursprung (anchorPoint 0.5, 0.2 laut Vertrag).
    static func tower(_ kind: TowerKind, field: CGFloat) -> SKNode {
        let node = SKNode()
        node.name = towerName(kind)
        let height = BattleStyle.towerHeight * field
        if let texture = texture(named: towerName(kind)) {
            let side = BattleStyle.towerSpriteSide * field
            let sprite = SKSpriteNode(texture: texture)
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.2)
            sprite.size = CGSize(width: side, height: side)
            node.addChild(sprite)
        } else {
            let width = BattleStyle.towerFootprint * field
            let body = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: width * 0.2)
            body.fillColor = BattleStyle.towerColor(kind)
            body.strokeColor = .black
            body.lineWidth = 1.5
            body.position = CGPoint(x: 0, y: height * 0.3)
            node.addChild(body)
        }
        return node
    }

    /// Festung, Fuß auf dem Ursprung; nil, solange kein Bild im Katalog liegt.
    static func fortress(field: CGFloat) -> SKSpriteNode? {
        guard let texture = texture(named: fortressName) else { return nil }
        let side = BattleStyle.fortressSpriteSide * field
        let sprite = SKSpriteNode(texture: texture)
        sprite.name = fortressName
        sprite.anchorPoint = CGPoint(x: 0.5, y: BattleStyle.fortressAnchorY)
        sprite.size = CGSize(width: side, height: side)
        return sprite
    }

    /// Gemalter Boden über die ganze Karte und `groundMargin` Zellen Wald
    /// ringsum, Weg eingemalt. Liegt er im Katalog, entfällt die gezeichnete
    /// Weglinie; die Bauzonen bleiben als Overlay.
    static func ground(missionID: String, layout: BoardLayout) -> SKSpriteNode? {
        let name = groundName(missionID: missionID)
        guard let texture = texture(named: name) else { return nil }
        let sprite = SKSpriteNode(texture: texture)
        sprite.name = name
        let margin = BattleStyle.groundMargin
        sprite.anchorPoint = .zero
        sprite.size = CGSize(width: layout.field * (CGFloat(layout.columns) + 2 * margin.width),
                             height: layout.field * (CGFloat(layout.rows) + 2 * margin.height))
        // Linke untere Ecke des Bildes in Szenenkoordinaten.
        sprite.position = layout.scenePoint(Point(x: -Double(margin.width), y: Double(layout.rows) + Double(margin.height)))
        sprite.zPosition = BattleStyle.groundZ
        return sprite
    }

    /// Gerenderte Bildfolge eines Gegners (FX 02), z. B. `enemy_raider_walk_00`
    /// bis `_07`. Geladen bis zum ersten fehlenden Bild; die Lückenlosigkeit
    /// prüft `check_assets.py` gegen den Vertrag. Einmal je Name, nicht je
    /// Gegner, denn eine Welle legt Dutzende an.
    static func frames(_ kind: EnemyKind, _ motion: EnemyMotion) -> [SKTexture] {
        let name = "\(enemyName(kind))_\(motion.rawValue)"
        if let cached = frameCache[name] { return cached }
        var textures: [SKTexture] = []
        while textures.count < 100, let next = texture(named: name + String(format: "_%02d", textures.count)) {
            textures.append(next)
        }
        frameCache[name] = textures
        return textures
    }

    private static var frameCache: [String: [SKTexture]] = [:]

    static func enemyBody(_ kind: EnemyKind, field: CGFloat) -> SKNode {
        let height = BattleStyle.enemyHeight(kind) * field
        if let texture = frames(kind, .walk).first ?? texture(named: enemyName(kind)) {
            let sprite = SKSpriteNode(texture: texture)
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.1)
            sprite.size = CGSize(width: height, height: height)
            return sprite
        }
        let body = SKShapeNode(ellipseOf: CGSize(width: height * 0.8, height: height))
        body.fillColor = BattleStyle.enemyColor(kind)
        body.strokeColor = .black
        body.lineWidth = 1.5
        body.position = CGPoint(x: 0, y: height * 0.5)
        return body
    }
}

/// Bildfolgen eines Gegners; die Namen stehen im Asset-Vertrag.
enum EnemyMotion: String, CaseIterable {
    case walk, hit, die
    /// Nur der Boss (FX 03): Schild heben, und aus der Schildhaltung rufen.
    case shield, summon
}

/// Ein Gegner, in Ebenen gebaut, damit sich Bewegungen nicht gegenseitig
/// überschreiben: Schatten am Boden; `motion` trägt die Laufhaltung (Hüpfen,
/// Stauchen, Kippen, Blickrichtung) aus `FxMath.pose`; `reaction` darunter
/// trägt Treffer, Erscheinen und Tod (FxDirector). Lebensbalken nur bei
/// Schaden (Marktanalyse E3), mit nachlaufendem hellem Schadensstück.
@MainActor
final class EnemyNode: SKNode {
    let enemyID: Int
    let kind: EnemyKind
    let motion = SKNode()
    let reaction = SKNode()
    let body: SKNode
    /// Additive Kopie des Bildes: Treffer-Aufblitzen ohne eigenen Shader.
    let flash: SKSpriteNode?
    let height: CGFloat
    /// 1 = Blick nach rechts (so sind die Bilder gemalt), −1 nach links.
    var facing: CGFloat = 1
    /// Bildfolgen (FX 02); leer, wenn die Art nur ein Standbild hat.
    let walkFrames: [SKTexture]
    let hitFrames: [SKTexture]
    let dieFrames: [SKTexture]
    /// Boss (FX 03): Schild heben (letztes Bild = Schildhaltung) und Ruf.
    let shieldFrames: [SKTexture]
    let summonFrames: [SKTexture]
    /// Haltung, zu der `release` zurückkehrt, solange der Schild steht; sonst nil (Laufbild).
    private(set) var guardFrame: SKTexture?
    /// Solange Treffer oder Sturz spielen, bestimmt der Director das Bild, nicht der Lauf.
    private(set) var holdsFrame = false
    /// Für die Darstellungstests: Nummer des gezeigten Laufbilds.
    private(set) var walkIndex = 0
    var hasFrames: Bool { !walkFrames.isEmpty }
    /// Effekt-Uhr des letzten Aufblitzens (Grenze je Gegner).
    var lastHit: Double = -.infinity
    /// Effekt-Uhr des letzten Funkens an der Panzerung (P2-10), eigene Grenze.
    var lastArmorSpark: Double = -.infinity
    /// Der Boss (P3-4) zeigt sein Leben in der Kopfleiste, nicht über dem Kopf.
    let isBoss: Bool
    /// Kuppel, solange der Schild des Bosses steht.
    private let shieldDome = SKSpriteNode()
    private var shieldTime: Double = 0
    /// Schild neben der Lebensleiste, nur bei Gegnern mit Rüstung (E3, P2-10).
    private(set) var armorBadge: SKShapeNode?
    var isArmored: Bool { armorBadge != nil }
    private let shadow = SKSpriteNode()
    /// Sporenschimmer am Boden, solange verlangsamt (P2-8): Der Farbton allein
    /// ging im Getümmel unter.
    private let slowAura = SKSpriteNode()
    private var auraTime: Double = 0
    private let health = SKSpriteNode()
    private let healthLag = SKSpriteNode()
    private let healthFill = SKSpriteNode()
    /// Mondmal (R-4): leuchtender Mond über dem Kopf, wippt mit dem Lauf.
    private let moonMark = SKSpriteNode()
    /// Betäubt (Steinregen): Sternchen kreisen über dem Kopf.
    private let stars = SKNode()
    private var starAngle: Double = 0
    private let healthWidth: CGFloat
    private var shownFraction: Double = 1

    init(enemy: Enemy, field: CGFloat, armored: Bool = false, boss: Bool = false) {
        enemyID = enemy.id
        kind = enemy.kind
        isBoss = boss
        body = BattleSprites.enemyBody(enemy.kind, field: field)
        walkFrames = BattleSprites.frames(enemy.kind, .walk)
        hitFrames = BattleSprites.frames(enemy.kind, .hit)
        dieFrames = BattleSprites.frames(enemy.kind, .die)
        shieldFrames = BattleSprites.frames(enemy.kind, .shield)
        summonFrames = BattleSprites.frames(enemy.kind, .summon)
        height = BattleStyle.enemyHeight(enemy.kind) * field
        healthWidth = BattleStyle.healthWidth * field
        if let sprite = body as? SKSpriteNode {
            let copy = SKSpriteNode(texture: sprite.texture)
            copy.anchorPoint = sprite.anchorPoint
            copy.size = sprite.size
            copy.blendMode = .add
            copy.alpha = 0
            flash = copy
        } else {
            flash = nil
        }
        super.init()
        name = BattleSprites.enemyName(enemy.kind)

        shadow.texture = FxTextures.texture(.glow)
        shadow.color = .black
        shadow.colorBlendFactor = 1
        shadow.alpha = FxStyle.shadowAlpha
        shadow.size = CGSize(width: height * 0.95, height: height * 0.32)
        addChild(shadow)
        slowAura.texture = FxTextures.texture(.glow)
        slowAura.color = FxStyle.sporeColor
        slowAura.colorBlendFactor = 1
        slowAura.blendMode = .add
        slowAura.size = CGSize(width: height * FxStyle.slowAuraWidth, height: height * FxStyle.slowAuraWidth * 0.36)
        slowAura.isHidden = true
        addChild(slowAura)
        addChild(motion)
        motion.addChild(reaction)
        reaction.addChild(body)
        if let flash { reaction.addChild(flash) }
        shieldDome.texture = FxTextures.texture(.glow)
        shieldDome.color = FxStyle.shieldColor
        shieldDome.colorBlendFactor = 1
        shieldDome.blendMode = .add
        shieldDome.size = CGSize(width: height * FxStyle.shieldWidth, height: height * FxStyle.shieldWidth)
        shieldDome.position = CGPoint(x: 0, y: height * 0.5)
        shieldDome.isHidden = true
        shieldDome.name = "boss.shield"
        addChild(shieldDome)

        let barHeight = BattleStyle.healthHeight * field
        health.color = BattleStyle.healthBack
        health.size = CGSize(width: healthWidth + 2, height: barHeight + 2)
        health.position = CGPoint(x: 0, y: height * 1.15)
        for (bar, color) in [(healthLag, FxStyle.healthLag), (healthFill, BattleStyle.healthFill)] {
            bar.color = color
            bar.anchorPoint = CGPoint(x: 0, y: 0.5)
            bar.size = CGSize(width: healthWidth, height: barHeight)
            bar.position = CGPoint(x: -healthWidth / 2, y: 0)
            health.addChild(bar)
        }
        health.isHidden = true
        addChild(health)

        // Das Schild steht immer, nicht nur bei Schaden wie die Leiste: Umriss
        // und Symbol sagen „gepanzert“, bevor der erste Schuss fällt (E3).
        if armored {
            let badge = SKShapeNode(path: BattleSprites.shieldPath(size: field * BattleStyle.armorBadgeSize))
            badge.fillColor = BattleStyle.armorBadgeFill
            badge.strokeColor = BattleStyle.armorBadgeStroke
            badge.lineWidth = 1.5
            badge.position = CGPoint(x: -healthWidth / 2 - field * BattleStyle.armorBadgeSize * 0.7, y: height * 1.15)
            badge.name = "armor.badge"
            addChild(badge)
            armorBadge = badge
        }

        moonMark.texture = FxTextures.texture(.glow)
        moonMark.color = BattleStyle.markTint
        moonMark.colorBlendFactor = 1
        moonMark.blendMode = .add
        moonMark.size = CGSize(width: height * 0.5, height: height * 0.5)
        moonMark.position = CGPoint(x: 0, y: height * 1.4)
        moonMark.isHidden = true
        motion.addChild(moonMark)

        stars.position = CGPoint(x: 0, y: height * FxStyle.stunHeight)
        stars.isHidden = true
        for _ in 0..<FxStyle.stunStars {
            let star = SKSpriteNode(texture: FxTextures.texture(.star))
            star.size = CGSize(width: field * FxStyle.stunStarSize, height: field * FxStyle.stunStarSize)
            stars.addChild(star)
        }
        motion.addChild(stars)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("nicht benutzt") }

    /// Haltung im Lauf. Spiegeln und Kippen hängen zusammen: Nach links
    /// gespiegelt kippt die Vorneigung in die andere Richtung.
    func apply(_ pose: Pose, field: CGFloat) {
        motion.position = CGPoint(x: 0, y: CGFloat(pose.lift) * field)
        motion.xScale = CGFloat(pose.scaleX) * facing
        motion.yScale = CGFloat(pose.scaleY)
        motion.zRotation = CGFloat(pose.tilt) * facing
        shadow.setScale(CGFloat(pose.shadow))
    }

    /// Laufbild aus der Strecke (`FxMath.walkFrame`); ohne Folge bleibt das Standbild.
    func walk(distance: Double, phase: Double) {
        guard hasFrames, !holdsFrame else { return }
        let index = FxMath.walkFrame(distance: distance, phase: phase,
                                     stride: FxStyle.frameStride, frames: walkFrames.count)
        guard index != walkIndex else { return }
        walkIndex = index
        setTexture(walkFrames[index])
    }

    /// Treffer oder Sturz: zeigt ein Bild der Folge und hält es gegen den Lauf.
    func hold(_ texture: SKTexture) {
        holdsFrame = true
        setTexture(texture)
    }

    /// Zurück zum Lauf, beim nächsten Bild der Szene; hinter dem Schild zurück in die Schildhaltung.
    func release() {
        if let guardFrame {
            holdsFrame = true
            setTexture(guardFrame)
            return
        }
        holdsFrame = false
        if hasFrames { setTexture(walkFrames[walkIndex]) }
    }

    /// Schildhaltung setzen (nil = wieder laufen). Nur der Director ruft das.
    func guardPose(_ texture: SKTexture?) {
        guardFrame = texture
    }

    private func setTexture(_ texture: SKTexture) {
        (body as? SKSpriteNode)?.texture = texture
        flash?.texture = texture
    }

    /// Verlangsamt im zuletzt gezeigten Zustand. Bild, Ton und Sporenfunke lesen
    /// es hier, damit sie dasselbe meinen.
    var isSlowed: Bool { !slowAura.isHidden }

    /// Lebensbalken und Verlangsamung aus dem Zustand; `dt` für das
    /// nachlaufende Schadensstück.
    func show(_ enemy: Enemy, dt: Double = 0, stunned: Bool = false) {
        let fraction = max(0, min(1, enemy.hp / enemy.maxHP))
        shownFraction = FxMath.lag(shownFraction, towards: fraction, dt: dt, rate: FxStyle.healthLagRate)
        health.isHidden = isBoss || fraction >= 1
        healthFill.size.width = healthWidth * CGFloat(fraction)
        healthLag.size.width = healthWidth * CGFloat(shownFraction)
        let slowed = enemy.slow != nil
        if let sprite = body as? SKSpriteNode {
            sprite.color = FxStyle.slowTint
            sprite.colorBlendFactor = slowed ? FxStyle.slowTintFactor : 0
        }
        shieldDome.isHidden = enemy.shieldUntilTick == nil
        if !shieldDome.isHidden {
            shieldTime += dt
            shieldDome.alpha = FxStyle.shieldAlpha * CGFloat(0.8 + 0.2 * sin(shieldTime * FxStyle.shieldBreath))
        }
        slowAura.isHidden = !slowed
        if slowed {
            auraTime += dt
            slowAura.alpha = FxStyle.slowAuraAlpha * CGFloat(0.8 + 0.2 * sin(auraTime * FxStyle.slowAuraBreath))
        }
        moonMark.isHidden = enemy.vulnerable == nil
        if !moonMark.isHidden {
            moonMark.alpha = CGFloat(0.75 + 0.25 * sin(starAngle * 0.8))
        }
        stars.isHidden = !stunned
        starAngle += dt * FxStyle.stunSpin
        if stunned {
            // Kreis von schräg oben gesehen: hinten kleiner und blasser.
            let radius = Double(height) * FxStyle.stunRadius
            for (index, star) in stars.children.enumerated() {
                let angle = starAngle + Double(index) / Double(stars.children.count) * 2 * Double.pi
                star.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius * 0.35)
                let front = (1 - sin(angle)) / 2
                star.setScale(CGFloat(0.7 + 0.3 * front))
                star.alpha = CGFloat(0.55 + 0.45 * front)
                star.zRotation = CGFloat(angle * 0.5)
            }
        }
    }

    /// Für die Darstellungstests: ob die Schildkuppel steht.
    var showsShield: Bool { !shieldDome.isHidden }
    /// Für die Darstellungstests: ob der Lebensbalken über dem Kopf zu sehen ist.
    var showsHealth: Bool { !health.isHidden }

    /// Für die Darstellungstests: ob Sternchen kreisen.
    var showsStun: Bool { !stars.isHidden }

    /// Für die Darstellungstests: ob das Mondmal gerade zu sehen ist.
    var showsMoonMark: Bool { !moonMark.isHidden }

    /// Lebensbalken weg, sobald der Gegner stirbt oder durchbricht.
    func hideHealth() { health.isHidden = true }
}

/// Ein Turm in Ebenen: `lift` trägt Bau und Verkauf, `pulse` Rückstoß und das
/// Pumpen des Sporenturms, `art` das leichte Atmen in Ruhe. Der Blitzturm hat
/// ein Glühen am Kristall.
@MainActor
final class TowerNode: SKNode {
    let towerID: Int
    let kind: TowerKind
    let lift = SKNode()
    let pulse = SKNode()
    let art: SKNode
    let glow: SKSpriteNode?
    /// Aufleuchten beim Schuss, 0 bis 1; die Szene addiert es zum Ruheglühen.
    var flare: CGFloat = 0
    /// Zwergenbank (P2-5): Balken „ausgezahlt von Obergrenze“ am Fuß. Nur bei
    /// der Bank vorhanden; leer wird sie grau, damit man sie verkauft.
    let bankBar: SKSpriteNode?
    private let bankFill = SKSpriteNode()
    private let bankWidth: CGFloat
    private(set) var bankEmpty = false

    init(tower: Tower, field: CGFloat) {
        towerID = tower.id
        kind = tower.kind
        art = BattleSprites.tower(tower.kind, field: field)
        if tower.kind == .lightning {
            let glow = SKSpriteNode(texture: FxTextures.texture(.glow))
            glow.color = FxStyle.crystalGlow
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.size = CGSize(width: field * 0.9, height: field * 0.9)
            glow.position = CGPoint(x: 0, y: FxStyle.crystalHeight * field)
            self.glow = glow
        } else {
            glow = nil
        }
        bankWidth = BattleStyle.healthWidth * field
        if tower.kind == .bank {
            let bar = SKSpriteNode(color: BattleStyle.healthBack,
                                   size: CGSize(width: bankWidth + 2, height: BattleStyle.healthHeight * field + 2))
            bar.position = CGPoint(x: 0, y: -BattleStyle.bankBarDrop * field)
            bar.zPosition = 2
            bankBar = bar
        } else {
            bankBar = nil
        }
        super.init()
        name = art.name
        addChild(lift)
        lift.addChild(pulse)
        pulse.addChild(art)
        if let glow { pulse.addChild(glow) }
        if let bankBar {
            bankFill.color = BattleStyle.bankFill
            bankFill.anchorPoint = CGPoint(x: 0, y: 0.5)
            bankFill.size = CGSize(width: 0, height: BattleStyle.healthHeight * field)
            bankFill.position = CGPoint(x: -bankWidth / 2, y: 0)
            bankBar.addChild(bankFill)
            addChild(bankBar)
        }
    }

    /// Anteil der Bank am Gold, das sie höchstens auszahlt, 0 bis 1.
    var bankFraction: CGFloat { bankWidth > 0 ? bankFill.size.width / bankWidth : 0 }

    /// Stand der Bank aus dem Zustand. Leer: grau und blass (07, „Zwergenbank“).
    func showBank(paid: Int, cap: Int) {
        guard bankBar != nil else { return }
        let fraction = cap > 0 ? min(1, CGFloat(paid) / CGFloat(cap)) : 1
        bankFill.size.width = bankWidth * fraction
        let empty = paid >= cap
        guard empty != bankEmpty else { return }
        bankEmpty = empty
        bankFill.color = empty ? BattleStyle.bankSpent : BattleStyle.bankFill
        art.alpha = empty ? BattleStyle.bankEmptyAlpha : 1
        for case let sprite as SKSpriteNode in art.children {
            sprite.color = .gray
            sprite.colorBlendFactor = empty ? 0.8 : 0
        }
    }

    /// Stufe aus dem Zustand: Bild der Stufe, wenn es im Katalog liegt, und
    /// ein Schild „II“ bzw. „III“ oben rechts, damit man es auch ohne neues Bild sieht (07).
    private(set) var level = 1
    private var badge: SKNode?

    func showLevel(_ newLevel: Int, field: CGFloat) {
        guard newLevel != level else { return }
        level = newLevel
        if let texture = BattleSprites.texture(named: BattleSprites.towerName(kind, level: newLevel)) {
            for case let sprite as SKSpriteNode in art.children { sprite.texture = texture }
        }
        badge?.removeFromParent()
        badge = nil
        guard newLevel >= 2 else { return }
        let plate = SKShapeNode(rectOf: CGSize(width: field * 0.36, height: field * 0.24), cornerRadius: field * 0.08)
        plate.fillColor = BattleStyle.levelBadgeFill
        plate.strokeColor = BattleStyle.levelBadgeStroke
        plate.lineWidth = 1.5
        let text = SKLabelNode(text: BattleTexts.levelTag(newLevel))
        text.fontName = BattleStyle.font
        text.fontSize = field * 0.2
        text.fontColor = BattleStyle.levelBadgeStroke
        text.verticalAlignmentMode = .center
        plate.addChild(text)
        plate.position = CGPoint(x: field * 0.38, y: field * 1.15)
        plate.zPosition = 3
        plate.name = "level.badge"
        addChild(plate)
        badge = plate
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("nicht benutzt") }

    /// Ruhe: Atmen und Glühen aus der Effekt-Uhr. Phase aus der Kennung, damit
    /// nicht alle Türme im Takt atmen.
    func idle(time: Double, still: Bool) {
        let phase = FxMath.phase(forID: towerID) * 2 * Double.pi
        let wave = still ? 0 : CGFloat(sin(time * 2 * Double.pi / FxStyle.breathPeriod + phase))
        art.yScale = 1 + FxStyle.breathAmount * wave
        glow?.alpha = min(1, 0.35 + 0.12 * wave + flare)
        glow?.setScale(1 + 0.6 * flare)
    }
}
