import OddlingsCore
import SpriteKit
import UIKit

/// Bilder nach den Namen aus dem Asset-Vertrag (tower_watch, enemy_raider, …).
/// Liegt ein Bild im Katalog, wird es benutzt, sonst eine Platzhalterform.
/// So ist der Tausch gegen echte Grafik nur ein neuer Katalog, kein Codeumbau.
@MainActor
enum BattleSprites {
    static func towerName(_ kind: TowerKind) -> String { "tower_\(kind.rawValue)" }
    static func enemyName(_ kind: EnemyKind) -> String { "enemy_\(kind.rawValue)" }

    static func texture(named name: String) -> SKTexture? {
        UIImage(named: name) == nil ? nil : SKTexture(imageNamed: name)
    }

    /// Turm, Fußpunkt auf dem Ursprung (anchorPoint 0.5, 0.2 laut Vertrag).
    static func tower(_ kind: TowerKind, field: CGFloat) -> SKNode {
        let node = SKNode()
        node.name = towerName(kind)
        let height = BattleStyle.towerHeight * field
        if let texture = texture(named: towerName(kind)) {
            let sprite = SKSpriteNode(texture: texture)
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.2)
            sprite.size = CGSize(width: height, height: height)
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

    static func enemyBody(_ kind: EnemyKind, field: CGFloat) -> SKNode {
        let height = BattleStyle.enemyHeight(kind) * field
        if let texture = texture(named: enemyName(kind)) {
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

/// Ein Gegner: Schatten unten, Körper darüber (für Hüpfen und Neigung, die
/// später prozedural dazukommen), Lebensbalken nur bei Schaden (Marktanalyse E3).
@MainActor
final class EnemyNode: SKNode {
    let enemyID: Int
    let body: SKNode
    private let health = SKSpriteNode()
    private let healthFill = SKSpriteNode()
    private let slowMark = SKShapeNode()
    private let healthWidth: CGFloat

    init(enemy: Enemy, field: CGFloat) {
        enemyID = enemy.id
        body = BattleSprites.enemyBody(enemy.kind, field: field)
        healthWidth = BattleStyle.healthWidth * field
        super.init()
        name = BattleSprites.enemyName(enemy.kind)

        let height = BattleStyle.enemyHeight(enemy.kind) * field
        let shadow = SKShapeNode(ellipseOf: CGSize(width: height * 0.9, height: height * 0.3))
        shadow.fillColor = BattleStyle.shadow
        shadow.strokeColor = .clear
        addChild(shadow)
        addChild(body)

        let barHeight = BattleStyle.healthHeight * field
        health.color = BattleStyle.healthBack
        health.size = CGSize(width: healthWidth, height: barHeight)
        health.position = CGPoint(x: 0, y: height * 1.15)
        healthFill.color = BattleStyle.healthFill
        healthFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthFill.size = CGSize(width: healthWidth, height: barHeight)
        healthFill.position = CGPoint(x: -healthWidth / 2, y: 0)
        health.addChild(healthFill)
        health.isHidden = true
        addChild(health)

        slowMark.path = CGPath(ellipseIn: CGRect(x: -height * 0.55, y: -height * 0.2,
                                                 width: height * 1.1, height: height * 0.4), transform: nil)
        slowMark.strokeColor = BattleStyle.slowTint
        slowMark.lineWidth = 2
        slowMark.isHidden = true
        addChild(slowMark)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("nicht benutzt") }

    func show(_ enemy: Enemy) {
        let fraction = max(0, min(1, enemy.hp / enemy.maxHP))
        health.isHidden = fraction >= 1
        healthFill.size.width = healthWidth * CGFloat(fraction)
        slowMark.isHidden = enemy.slow == nil
    }

    func flash() {
        body.removeAction(forKey: "flash")
        body.run(.sequence([
            .fadeAlpha(to: 0.35, duration: BattleStyle.hitFlash),
            .fadeAlpha(to: 1, duration: BattleStyle.hitFlash),
        ]), withKey: "flash")
    }
}
