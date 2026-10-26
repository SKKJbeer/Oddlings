import Foundation

/// Eine verletzte Regel, mit dem Ort in der Datei. Der Ort ist der Sinn der
/// Sache: Wer Balancewerte ändert, soll nicht raten müssen, welche Zahl es war.
public struct ConfigIssue: Equatable, Sendable, CustomStringConvertible {
    public var field: String
    public var rule: Rule

    public enum Rule: Equatable, Sendable {
        case mustBePositive
        case mustNotBeNegative
        case mustBeFraction            // in (0, 1]
        case mustBeRate                // in [0, 1]
        case missingTower
        case missingEnemy
        case missingChainValues
        case missingSlowValues
        case pathTooShort
        case noWaves
        case emptyWave
        case starsOutOfOrder           // 0 < two ≤ three ≤ fortressLives
        case delayNotBelowCooldown
    }

    public init(field: String, rule: Rule) {
        self.field = field
        self.rule = rule
    }

    public var description: String {
        switch rule {
        case .mustBePositive: "\(field) muss größer als 0 sein"
        case .mustNotBeNegative: "\(field) darf nicht negativ sein"
        case .mustBeFraction: "\(field) muss größer als 0 und höchstens 1 sein"
        case .mustBeRate: "\(field) muss zwischen 0 und 1 liegen"
        case .missingTower: "\(field) fehlt"
        case .missingEnemy: "\(field) verweist auf einen Gegner ohne Werte"
        case .missingChainValues: "\(field) braucht chainJumps, chainRadius und chainFalloff"
        case .missingSlowValues: "\(field) braucht slowFactor und slowDuration"
        case .pathTooShort: "\(field) braucht mindestens zwei Punkte"
        case .noWaves: "\(field) braucht mindestens eine Welle"
        case .emptyWave: "\(field) braucht mindestens eine Gruppe"
        case .delayNotBelowCooldown: "\(field) muss kleiner als cooldown sein"
        case .starsOutOfOrder: "\(field) braucht 0 < two ≤ three ≤ fortressLives"
        }
    }
}

public enum ConfigError: Error, Equatable, CustomStringConvertible {
    case resourceMissing(String)
    case unreadable(String)
    case invalid([ConfigIssue])

    public var description: String {
        switch self {
        case .resourceMissing(let name): "Konfiguration \(name) nicht gefunden"
        case .unreadable(let reason): "Konfiguration nicht lesbar: \(reason)"
        case .invalid(let issues): issues.map(\.description).joined(separator: "\n")
        }
    }
}

extension BalanceConfig {
    /// Alle Verstöße auf einmal statt nur des ersten: Eine Balancerunde ändert
    /// oft mehrere Werte, und jeder Fehler einzeln wäre ein Lauf je Zahl.
    public func issues() -> [ConfigIssue] {
        var found: [ConfigIssue] = []
        func positive(_ value: Double, _ field: String) {
            if !(value > 0) { found.append(.init(field: field, rule: .mustBePositive)) }
        }
        func nonNegative(_ value: Double, _ field: String) {
            if !(value >= 0) { found.append(.init(field: field, rule: .mustNotBeNegative)) }
        }
        func fraction(_ value: Double, _ field: String) {
            if !(value > 0 && value <= 1) { found.append(.init(field: field, rule: .mustBeFraction)) }
        }

        positive(Double(simulation.ticksPerSecond), "simulation.ticksPerSecond")

        positive(Double(mission.fortressLives), "mission.fortressLives")
        nonNegative(Double(mission.startGold), "mission.startGold")
        nonNegative(mission.firstWaveDelay, "mission.firstWaveDelay")
        nonNegative(mission.timeBetweenWaves, "mission.timeBetweenWaves")
        if !(mission.sellRefundRate >= 0 && mission.sellRefundRate <= 1) {
            found.append(.init(field: "mission.sellRefundRate", rule: .mustBeRate))
        }
        // Ohne gültige Leben wäre jede Sterngrenze falsch; das meldet schon die
        // Zeile darüber, ein zweiter Fehler für dieselbe Zahl hülfe niemandem.
        if let stars = mission.stars, mission.fortressLives > 0,
           !(stars.two > 0 && stars.two <= stars.three && stars.three <= mission.fortressLives) {
            found.append(.init(field: "mission.stars", rule: .starsOutOfOrder))
        }

        positive(Double(map.width), "map.width")
        positive(Double(map.height), "map.height")
        nonNegative(map.minDistanceFromPath, "map.minDistanceFromPath")
        if map.path.count < 2 { found.append(.init(field: "map.path", rule: .pathTooShort)) }

        for kind in TowerKind.allCases {
            let field = "towers.\(kind.rawValue)"
            guard let tower = towers[kind] else {
                found.append(.init(field: field, rule: .missingTower))
                continue
            }
            positive(Double(tower.cost), "\(field).cost")
            positive(tower.range, "\(field).range")
            nonNegative(tower.damage, "\(field).damage")
            positive(tower.attackInterval, "\(field).attackInterval")
            if kind == .lightning {
                if let jumps = tower.chainJumps, let radius = tower.chainRadius, let falloff = tower.chainFalloff {
                    nonNegative(Double(jumps), "\(field).chainJumps")
                    positive(radius, "\(field).chainRadius")
                    fraction(falloff, "\(field).chainFalloff")
                } else {
                    found.append(.init(field: field, rule: .missingChainValues))
                }
            }
            if kind == .spore {
                if let factor = tower.slowFactor, let duration = tower.slowDuration {
                    fraction(factor, "\(field).slowFactor")
                    positive(duration, "\(field).slowDuration")
                } else {
                    found.append(.init(field: field, rule: .missingSlowValues))
                }
            }
        }

        for kind in EnemyKind.allCases {
            guard let enemy = enemies[kind] else { continue }
            let field = "enemies.\(kind.rawValue)"
            positive(enemy.hp, "\(field).hp")
            positive(enemy.speed, "\(field).speed")
            nonNegative(Double(enemy.reward), "\(field).reward")
            positive(Double(enemy.leakDamage), "\(field).leakDamage")
        }

        if let ability {
            positive(ability.radius, "ability.radius")
            nonNegative(ability.damage, "ability.damage")
            nonNegative(ability.delay, "ability.delay")
            nonNegative(ability.stunDuration, "ability.stunDuration")
            positive(ability.cooldown, "ability.cooldown")
            nonNegative(ability.snapDistance, "ability.snapDistance")
            // Sonst läge der Einschlag nach der nächsten Bereitschaft, und ein
            // zweiter Wurf überschriebe den ersten, bevor er trifft.
            if !(ability.delay < ability.cooldown) {
                found.append(.init(field: "ability.delay", rule: .delayNotBelowCooldown))
            }
        }

        if waves.isEmpty { found.append(.init(field: "waves", rule: .noWaves)) }
        for (w, wave) in waves.enumerated() {
            let field = "waves[\(w)]"
            positive(wave.hpScale, "\(field).hpScale")
            if wave.groups.isEmpty { found.append(.init(field: field, rule: .emptyWave)) }
            for (g, group) in wave.groups.enumerated() {
                let groupField = "\(field).groups[\(g)]"
                if enemies[group.enemy] == nil {
                    found.append(.init(field: "\(groupField).enemy", rule: .missingEnemy))
                }
                positive(Double(group.count), "\(groupField).count")
                positive(group.interval, "\(groupField).interval")
                if let delay = group.delay { nonNegative(delay, "\(groupField).delay") }
            }
        }
        return found
    }

    public func validate() throws(ConfigError) {
        let found = issues()
        if !found.isEmpty { throw .invalid(found) }
    }

    /// Lesen und prüfen in einem Schritt, damit niemand eine ungeprüfte
    /// Konfiguration in die Simulation reicht.
    public static func load(from data: Data) throws(ConfigError) -> BalanceConfig {
        let config: BalanceConfig
        do {
            config = try JSONDecoder().decode(BalanceConfig.self, from: data)
        } catch {
            throw .unreadable(String(describing: error))
        }
        try config.validate()
        return config
    }

    /// Mission 1 aus den Paket-Ressourcen.
    public static func missionOne() throws(ConfigError) -> BalanceConfig {
        try bundled(named: "mvp-mission-01")
    }

    /// Eine Mission der Kampagne über den Dateinamen aus der Regionsdatei.
    public static func bundledMission(named name: String) throws(ConfigError) -> BalanceConfig {
        try bundled(named: name)
    }

    static func bundled(named name: String) throws(ConfigError) -> BalanceConfig {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Balance")
        else { throw .resourceMissing(name) }
        let data: Data
        do { data = try Data(contentsOf: url) } catch { throw .unreadable(String(describing: error)) }
        return try load(from: data)
    }
}
