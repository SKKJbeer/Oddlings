import Foundation

/// Eine verletzte Regel, mit dem Ort in der Datei. Der Ort ist der Sinn der
/// Sache: Wer Balancewerte ändert, soll nicht raten müssen, welche Zahl es war.
public struct ConfigIssue: Hashable, Sendable, CustomStringConvertible {
    public var field: String
    public var rule: Rule

    public enum Rule: Hashable, Sendable {
        case mustBePositive
        case mustNotBeNegative
        case mustBeFraction            // in (0, 1]
        case mustBeRate                // in [0, 1]
        case mustExceedOne             // > 1, ein Schadensfaktor, der etwas bewirkt
        case missingTower
        case missingEnemy
        case missingChainValues
        case missingSlowValues
        case pathTooShort
        case noWaves
        case emptyWave
        case starsOutOfOrder           // 0 < two ≤ three ≤ fortressLives
        case delayNotBelowCooldown
        case durationAboveCooldown
        case mustBeAboveOne
        case missingAbilityValue
        case missingRace
        case ranksOutOfOrder           // 0 < erste Schwelle < zweite < …
        case talentRowsDontMatchRanks  // eine Talentreihe je Rang über I
        case fieldNotInAbility         // Spielart skaliert ein Feld, das die Fähigkeit nicht hat
        case invalidID                 // Kleinbuchstaben, Ziffern, Bindestrich
        case duplicateID
        case unknownMission
        case starsAboveMaximum         // mehr Sterne, als eine Mission vergibt
        case fieldNotInSlot            // Stück verschiebt ein Feld eines anderen Platzes
        case noBonus
        case emptySlot
        case levelNotStronger          // höhere Stufe ist nicht besser als die vorige
        case levelFieldsDiffer         // Stufe verschiebt andere Felder als Stufe I
        case levelWithoutCost          // Stufe, für die die Schmiede keinen Preis kennt
        case bankNotATower             // Bank gehört in den Abschnitt `bank`, nicht in `towers`
        case strategyNeedsBank         // Bauweise nennt `bank`, die Mission hat keine
        case upgradeNeedsCombatTower   // Aufwertung nur für Kampftürme
        case emptyUpgrade              // Aufwertung ohne einen einzigen Faktor
        case statNotInTower            // Faktor auf einen Wert, den der Turm nicht hat
        case strategyNeedsUpgrades     // Bauweise wertet auf, die Mission bietet es nicht an
        case armorNeedsBothValues      // Rüstung braucht armor und armorMinShare zusammen
        case specializationNeedsUpgrade  // Stufe 3 ohne Stufe 2 für diesen Turm
        case emptySpecialization       // Spezialisierung ohne jede Wirkung
        case strategyNeedsSpecialization // Bauweise spezialisiert, die Mission bietet es nicht an
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
        case .mustExceedOne: "\(field) muss größer als 1 sein"
        case .mustBeRate: "\(field) muss zwischen 0 und 1 liegen"
        case .missingTower: "\(field) fehlt"
        case .missingEnemy: "\(field) verweist auf einen Gegner ohne Werte"
        case .missingChainValues: "\(field) braucht chainJumps, chainRadius und chainFalloff"
        case .missingSlowValues: "\(field) braucht slowFactor und slowDuration"
        case .pathTooShort: "\(field) braucht mindestens zwei Punkte"
        case .noWaves: "\(field) braucht mindestens eine Welle"
        case .emptyWave: "\(field) braucht mindestens eine Gruppe"
        case .delayNotBelowCooldown: "\(field) muss kleiner als cooldown sein"
        case .durationAboveCooldown: "\(field) darf nicht länger als cooldown sein"
        case .mustBeAboveOne: "\(field) muss größer als 1 sein"
        case .missingAbilityValue: "\(field) fehlt, die Art der Fähigkeit braucht es"
        case .missingRace: "\(field) fehlt"
        case .ranksOutOfOrder: "\(field) braucht steigende Schwellen größer als 0"
        case .talentRowsDontMatchRanks: "\(field) braucht genau eine Reihe je Rang über I"
        case .fieldNotInAbility: "\(field) gibt es bei dieser Fähigkeit nicht"
        case .bankNotATower: "\(field) gehört in den Abschnitt bank"
        case .strategyNeedsBank: "\(field) nennt bank, die Mission hat keine"
        case .upgradeNeedsCombatTower: "\(field) gibt es nur für watch, lightning und spore"
        case .emptyUpgrade: "\(field) braucht mindestens einen Faktor in scale"
        case .statNotInTower: "\(field) gibt es bei diesem Turm nicht"
        case .strategyNeedsUpgrades: "\(field) wertet auf, die Mission hat dafür keine Werte"
        case .armorNeedsBothValues: "\(field) braucht armor und armorMinShare zusammen"
        case .specializationNeedsUpgrade: "\(field) braucht eine Aufwertung auf Stufe 2 für diesen Turm"
        case .emptySpecialization: "\(field) braucht scale, targets, extraJumps, keepsDamageOnSlowed oder vulnerableFactor"
        case .strategyNeedsSpecialization: "\(field) spezialisiert, die Mission bietet es nicht an"
        case .starsOutOfOrder: "\(field) braucht 0 < two ≤ three ≤ fortressLives"
        case .invalidID: "\(field) darf nur Kleinbuchstaben, Ziffern und Bindestriche enthalten"
        case .duplicateID: "\(field) ist doppelt vergeben"
        case .unknownMission: "\(field) nennt eine Mission, die es in der Region nicht gibt"
        case .starsAboveMaximum: "\(field) ist mehr, als eine Mission an Sternen vergibt"
        case .fieldNotInSlot: "\(field) gehört zu einem anderen Platz"
        case .noBonus: "\(field) braucht mindestens einen Bonus"
        case .emptySlot: "\(field) braucht mindestens ein Stück"
        case .levelNotStronger: "\(field) muss stärker sein als die Stufe davor"
        case .levelFieldsDiffer: "\(field) muss dieselben Felder verschieben wie Stufe I"
        case .levelWithoutCost: "\(field) hat mehr Stufen, als die Schmiede Preise kennt"
        }
    }
}

extension AbilityConfig {
    /// Die Felder, die `kind` braucht, und keine Grenze mehr: Ein überzähliges
    /// Feld schadet nicht, ein fehlendes hielte die Simulation an einer Stelle an,
    /// die niemand sucht.
    public func issues(field prefix: String) -> [ConfigIssue] {
        var found: [ConfigIssue] = []
        func required(_ value: Double?, _ name: String, _ check: (Double) -> ConfigIssue.Rule?) {
            let field = "\(prefix).\(name)"
            guard let value else { return found.append(.init(field: field, rule: .missingAbilityValue)) }
            if let rule = check(value) { found.append(.init(field: field, rule: rule)) }
        }
        let positive: (Double) -> ConfigIssue.Rule? = { $0 > 0 ? nil : .mustBePositive }
        let nonNegative: (Double) -> ConfigIssue.Rule? = { $0 >= 0 ? nil : .mustNotBeNegative }
        // Sonst läge die Wirkung nach der nächsten Bereitschaft, und ein zweiter
        // Wurf überschriebe den ersten, bevor er trifft.
        let beforeCooldown: (Double) -> ConfigIssue.Rule? = { [cooldown] value in
            !(value >= 0) ? .mustNotBeNegative : (value < cooldown ? nil : .delayNotBelowCooldown)
        }

        if !(cooldown > 0) { found.append(.init(field: "\(prefix).cooldown", rule: .mustBePositive)) }
        if !(snapDistance >= 0) { found.append(.init(field: "\(prefix).snapDistance", rule: .mustNotBeNegative)) }
        switch kind {
        case .stoneRain:
            required(radius, "radius", positive)
            required(damage, "damage", nonNegative)
            required(delay, "delay", beforeCooldown)
            required(stunDuration, "stunDuration", nonNegative)
        case .bulwark:
            // Eine Mauer zur Zeit: Die nächste darf erst stehen, wenn die alte fällt.
            required(duration, "duration") { [cooldown] value in
                !(value > 0) ? .mustBePositive : (value <= cooldown ? nil : .durationAboveCooldown)
            }
        case .moonMark:
            required(radius, "radius", positive)
            required(delay, "delay", beforeCooldown)
            required(duration, "duration", positive)
            required(damageFactor, "damageFactor") { $0 > 1 ? nil : .mustBeAboveOne }
        }
        return found
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
        if let bonus = mission.earlyCallBonus { nonNegative(bonus, "mission.earlyCallBonus") }
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

        if towers[.bank] != nil { found.append(.init(field: "towers.bank", rule: .bankNotATower)) }
        for kind in TowerKind.combat {
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
            switch (enemy.armor, enemy.armorMinShare) {
            case (nil, nil):
                break
            case let (armor?, share?):
                nonNegative(armor, "\(field).armor")
                fraction(share, "\(field).armorMinShare")
            default:
                found.append(.init(field: field, rule: .armorNeedsBothValues))
            }
        }

        if let ability { found += ability.issues(field: "ability") }

        if let bank {
            positive(Double(bank.cost), "bank.cost")
            nonNegative(bank.delay, "bank.delay")
            positive(bank.interval, "bank.interval")
            positive(Double(bank.payout), "bank.payout")
            positive(Double(bank.cap), "bank.cap")
            positive(Double(bank.limit), "bank.limit")
        }
        found += upgradeIssues()
        found += specializationIssues()
        // Nach Namen sortiert, damit die Meldungen bei gleicher Datei gleich sind.
        for name in (simStrategies ?? [:]).keys.sorted() {
            let steps = simStrategies?[name] ?? []
            if bank == nil && steps.contains(where: { $0.kind == .bank }) {
                found.append(.init(field: "simStrategies.\(name)", rule: .strategyNeedsBank))
            }
            if steps.contains(where: { if case .upgrade(let kind) = $0 { upgrades?[kind] == nil } else { false } }) {
                found.append(.init(field: "simStrategies.\(name)", rule: .strategyNeedsUpgrades))
            }
            if steps.contains(where: { if case .specialize(let s) = $0 { specializations?[s] == nil } else { false } }) {
                found.append(.init(field: "simStrategies.\(name)", rule: .strategyNeedsSpecialization))
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

    /// Aufwertungen: nur Kampftürme, Preis und Faktoren positiv, nur Werte, die
    /// der Turm hat, und Stufe 2 hält dieselben Grenzen wie Stufe 1.
    private func upgradeIssues() -> [ConfigIssue] {
        var found: [ConfigIssue] = []
        guard let upgrades else { return found }
        for kind in TowerKind.allCases {
            guard let upgrade = upgrades[kind] else { continue }
            let field = "upgrades.\(kind.rawValue)"
            guard let base = towers[kind], kind != .bank else {
                found.append(.init(field: field, rule: .upgradeNeedsCombatTower))
                continue
            }
            if !(upgrade.cost > 0) { found.append(.init(field: "\(field).cost", rule: .mustBePositive)) }
            if upgrade.scale.isEmpty { found.append(.init(field: "\(field).scale", rule: .emptyUpgrade)) }
            for stat in TowerStat.allCases {
                guard let factor = upgrade.scale[stat] else { continue }
                let statField = "\(field).scale.\(stat.rawValue)"
                if !(factor > 0) { found.append(.init(field: statField, rule: .mustBePositive)) }
                let present = switch stat {
                case .range, .damage, .attackInterval: true
                case .chainRadius: base.chainRadius != nil
                case .slowFactor, .slowDuration: base.slowFactor != nil
                }
                if !present { found.append(.init(field: statField, rule: .statNotInTower)) }
            }
            // Eine Verlangsamung über 1 wäre eine Beschleunigung.
            if let slow = upgrade.apply(to: base).slowFactor, !(slow > 0 && slow <= 1) {
                found.append(.init(field: "\(field).scale.slowFactor", rule: .mustBeFraction))
            }
        }
        return found
    }

    /// Spezialisierungen: nur auf einem Turm mit Stufe 2, Preis positiv, jede
    /// Wirkung passt zum Turm, und Stufe 3 hält dieselben Grenzen wie Stufe 1.
    private func specializationIssues() -> [ConfigIssue] {
        var found: [ConfigIssue] = []
        guard let specializations else { return found }
        for specialization in Specialization.allCases {
            guard let special = specializations[specialization] else { continue }
            let field = "specializations.\(specialization.rawValue)"
            let kind = specialization.tower
            guard let base = towers[kind], upgrades?[kind] != nil, let second = stats(of: kind, level: 2) else {
                found.append(.init(field: field, rule: .specializationNeedsUpgrade))
                continue
            }
            if !(special.cost > 0) { found.append(.init(field: "\(field).cost", rule: .mustBePositive)) }
            let scale = special.scale ?? [:]
            if scale.isEmpty && special.targets == nil && special.extraJumps == nil && special.keepsDamageOnSlowed == nil
                && special.vulnerableFactor == nil {
                found.append(.init(field: field, rule: .emptySpecialization))
            }
            for stat in TowerStat.allCases {
                guard let factor = scale[stat] else { continue }
                let statField = "\(field).scale.\(stat.rawValue)"
                if !(factor > 0) { found.append(.init(field: statField, rule: .mustBePositive)) }
                let present = switch stat {
                case .range, .damage, .attackInterval: true
                case .chainRadius: base.chainRadius != nil
                case .slowFactor, .slowDuration: base.slowFactor != nil
                }
                if !present { found.append(.init(field: statField, rule: .statNotInTower)) }
            }
            // Mehrere Ziele hat nur der Einzelschuss, Sprünge nur die Kette.
            if let targets = special.targets {
                if base.targeting != .first || base.chainJumps != nil {
                    found.append(.init(field: "\(field).targets", rule: .statNotInTower))
                } else if !(targets > 0) {
                    found.append(.init(field: "\(field).targets", rule: .mustBePositive))
                }
            }
            if special.extraJumps != nil || special.keepsDamageOnSlowed != nil, base.chainJumps == nil {
                found.append(.init(field: "\(field).extraJumps", rule: .statNotInTower))
            }
            if let jumps = special.extraJumps, let chain = second.chainJumps {
                nonNegativeInt(chain + jumps, "\(field).extraJumps", into: &found)
            }
            // Verwundbar macht nur, wer verlangsamt; ein Faktor ≤ 1 wäre keine Fäulnis.
            if let factor = special.vulnerableFactor {
                if base.slowFactor == nil {
                    found.append(.init(field: "\(field).vulnerableFactor", rule: .statNotInTower))
                } else if !(factor > 1) {
                    found.append(.init(field: "\(field).vulnerableFactor", rule: .mustExceedOne))
                }
            }
            if let slow = special.apply(to: second).slowFactor, !(slow > 0 && slow <= 1) {
                found.append(.init(field: "\(field).scale.slowFactor", rule: .mustBeFraction))
            }
        }
        return found
    }

    private func nonNegativeInt(_ value: Int, _ field: String, into found: inout [ConfigIssue]) {
        if value < 0 { found.append(.init(field: field, rule: .mustNotBeNegative)) }
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
