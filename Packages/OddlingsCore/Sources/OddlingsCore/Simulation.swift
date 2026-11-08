import Foundation

/// Regeln einer Mission. Hält Konfiguration und die daraus berechnete Karte,
/// damit `step` die Bauzonen nicht in jedem Tick neu ausrechnet. Der Zustand
/// liegt nie hier, sondern immer in `GameState`.
public struct Simulation: Sendable {
    public let config: BalanceConfig
    public let map: MissionMap

    public init(config: BalanceConfig) {
        self.config = config
        map = MissionMap(config: config.map)
    }

    public func newGame(seed: UInt64) -> GameState {
        GameState(
            tick: 0,
            gold: config.mission.startGold,
            fortressLives: config.mission.fortressLives,
            waveIndex: -1,
            nextWaveTick: config.waves.isEmpty ? nil : ticks(config.mission.firstWaveDelay),
            pendingSpawns: [],
            towers: [],
            enemies: [],
            nextEntityID: 1,
            outcome: nil,
            rng: SplitMix64(seed: seed)
        )
    }

    /// Sekunden aus der Konfiguration in ganze Ticks. Gerundet, nicht
    /// abgeschnitten: 1,3 s × 30 ergibt in Double 38,999…, gemeint sind 39.
    public func ticks(_ seconds: Double) -> Int {
        Int((seconds * Double(config.simulation.ticksPerSecond)).rounded())
    }

    /// Ein Tick. Die Reihenfolge ist festgeschrieben, weil sie Ergebnisse
    /// ändert (data-models.md): Befehle → Mauer fällt, Einschlag der Fähigkeit → Wellen/Spawns → Türme feuern (nach ID)
    /// → Bosse (Schild, Ruf) → Tote auswerten und Gold gutschreiben → Banken zahlen → Bewegung → Durchbrüche → Ende.
    /// Befehle laufen in der übergebenen Reihenfolge.
    @discardableResult
    public func step(_ state: inout GameState, commands: [Command] = []) -> [Event] {
        guard !state.isOver else { return [] }
        var events: [Event] = []
        for command in commands { apply(command, to: &state, &events) }
        resolveAbility(&state, &events)
        startWaveIfDue(&state, &events)
        spawnDue(&state, &events)
        fireTowers(&state, &events)
        runBosses(&state, &events)
        collectKills(&state, &events)
        payBanks(&state, &events)
        move(&state)
        leak(&state, &events)
        checkVictory(&state, &events)
        state.tick += 1
        return events
    }

    private func apply(_ command: Command, to state: inout GameState, _ events: inout [Event]) {
        switch command {
        case .build(let kind, let cell):
            guard let cost = config.cost(of: kind) else {
                return events.append(.commandRejected(command, reason: .unknownTower))
            }
            switch map.placement(of: cell, occupied: state.towers.map(\.cell)) {
            case .outsideMap: return events.append(.commandRejected(command, reason: .outsideMap))
            case .tooCloseToPath: return events.append(.commandRejected(command, reason: .tooCloseToPath))
            case .occupied: return events.append(.commandRejected(command, reason: .cellOccupied))
            case .free: break
            }
            if kind == .bank, let bank = config.bank, banks(in: state) >= bank.limit {
                return events.append(.commandRejected(command, reason: .limitReached))
            }
            guard state.gold >= cost else {
                return events.append(.commandRejected(command, reason: .notEnoughGold))
            }
            state.gold -= cost
            let id = state.nextEntityID
            state.nextEntityID += 1
            state.towers.append(Tower(id: id, kind: kind, cell: cell, cooldownTicks: 0, spent: cost,
                                      builtTick: state.tick))
            events.append(.towerBuilt(id: id))

        case .sell(let towerID):
            guard let index = state.towers.firstIndex(where: { $0.id == towerID }) else {
                return events.append(.commandRejected(command, reason: .unknownTower))
            }
            let refund = refund(for: state.towers[index].spent)
            state.gold += refund
            state.towers.remove(at: index)
            events.append(.towerSold(id: towerID, refund: refund))

        case .upgrade(let towerID):
            guard let index = state.towers.firstIndex(where: { $0.id == towerID }) else {
                return events.append(.commandRejected(command, reason: .unknownTower))
            }
            let tower = state.towers[index]
            guard tower.level < config.maxLevel(of: tower.kind), let cost = config.upgradeCost(of: tower.kind) else {
                return events.append(.commandRejected(command, reason: .notUpgradable))
            }
            guard state.gold >= cost else {
                return events.append(.commandRejected(command, reason: .notEnoughGold))
            }
            state.gold -= cost
            // Der Takt läuft weiter: Aufwerten mitten im Kampf kostet keinen Schuss.
            state.towers[index].level += 1
            state.towers[index].spent += cost
            events.append(.towerUpgraded(id: towerID, level: state.towers[index].level))

        case .specialize(let towerID, let specialization):
            guard let index = state.towers.firstIndex(where: { $0.id == towerID }) else {
                return events.append(.commandRejected(command, reason: .unknownTower))
            }
            let tower = state.towers[index]
            guard tower.level == 2, tower.specialization == nil,
                  config.specializations(for: tower.kind).contains(specialization),
                  let cost = config.specializations?[specialization]?.cost else {
                return events.append(.commandRejected(command, reason: .notUpgradable))
            }
            guard state.gold >= cost else {
                return events.append(.commandRejected(command, reason: .notEnoughGold))
            }
            state.gold -= cost
            // Wie beim Aufwerten läuft der Takt weiter.
            state.towers[index].level = 3
            state.towers[index].specialization = specialization
            state.towers[index].spent += cost
            events.append(.towerUpgraded(id: towerID, level: 3))

        case .setTargetMode(let towerID, let mode):
            guard let index = state.towers.firstIndex(where: { $0.id == towerID }) else {
                return events.append(.commandRejected(command, reason: .unknownTower))
            }
            let tower = state.towers[index]
            guard tower.level >= 2, config.stats(of: tower)?.targeting == .first else {
                return events.append(.commandRejected(command, reason: .targetModeLocked))
            }
            guard tower.targetMode != mode else { return }
            state.towers[index].targetMode = mode
            events.append(.targetModeChanged(id: towerID, mode: mode))

        case .callNextWave:
            guard state.nextWaveTick != nil else {
                return events.append(.commandRejected(command, reason: .noWaveLeft))
            }
            let bonus = earlyCallBonus(in: state)
            if bonus > 0 {
                state.gold += bonus
                events.append(.earlyCallBonus(gold: bonus))
            }
            // Der Plan verschiebt sich mit: Der Takt zur übernächsten Welle läuft
            // ab dem letzten Erscheinen dieser, wie bei einem regulären Start.
            state.nextWaveTick = state.tick

        case .useAbility(let point):
            guard let ability = config.ability else {
                return events.append(.commandRejected(command, reason: .noAbility))
            }
            guard state.tick >= state.ability.readyTick else {
                return events.append(.commandRejected(command, reason: .abilityNotReady))
            }
            let (center, along) = map.path.nearest(to: point)
            guard center.distance(to: point) <= ability.snapDistance else {
                return events.append(.commandRejected(command, reason: .notOnPath))
            }
            state.ability.readyTick = state.tick + ticks(ability.cooldown)
            switch ability.kind {
            case .stoneRain, .moonMark:
                let impact = state.tick + ticks(ability.delay ?? 0)
                state.ability.strike = Strike(center: center, impactTick: impact)
                events.append(.abilityCast(center: center, impactTick: impact))
            case .bulwark:
                // Steht sofort: Eine Mauer, die erst kommt, wenn die Gegner schon
                // vorbei sind, wäre keine Planung, sondern Glück.
                let until = state.tick + ticks(ability.duration ?? 0)
                state.ability.barrier = Barrier(distance: along, untilTick: until)
                events.append(.abilityCast(center: center, impactTick: state.tick))
                events.append(.barrierRaised(distance: along, untilTick: until))
            }
        }
    }

    /// Erst fällt eine abgelaufene Mauer, dann schlägt ein fälliger Wurf ein.
    /// Getroffen ist, wer beim Einschlag im Kreis steht, nicht wer beim Wurf dort
    /// stand: Der Schatten ist die Ankündigung, man zielt voraus (03).
    private func resolveAbility(_ state: inout GameState, _ events: inout [Event]) {
        if let barrier = state.ability.barrier, state.tick >= barrier.untilTick {
            state.ability.barrier = nil
            events.append(.barrierFell)
        }
        guard let strike = state.ability.strike, state.tick >= strike.impactTick,
              let ability = config.ability else { return }
        state.ability.strike = nil
        let hits = enemiesInRange(state.enemies, around: strike.center, range: ability.radius ?? 0)
        switch ability.kind {
        case .stoneRain:
            let until = state.tick + ticks(ability.stunDuration ?? 0)
            for hit in hits {
                // Kein Stapeln: Ein zweiter Treffer verlängert bis zu seinem Ende, nie darüber hinaus.
                let dealt = hurt(&state.enemies[hit], by: ability.damage ?? 0, tick: state.tick, piercesArmor: true)
                state.enemies[hit].stunUntilTick = max(state.enemies[hit].stunUntilTick ?? 0, until)
                events.append(.enemyDamaged(id: state.enemies[hit].id, amount: dealt))
            }
        case .moonMark:
            let mark = VulnerableEffect(factor: ability.damageFactor ?? 1,
                                        untilTick: state.tick + ticks(ability.duration ?? 0))
            for hit in hits { applyVulnerable(mark, to: &state.enemies[hit], tick: state.tick) }
        case .bulwark:
            break
        }
        events.append(.abilityImpact(center: strike.center, hits: hits.map { state.enemies[$0].id }))
    }

    /// Ergebnis eines Treffers: was ankam und was die Rüstung geschluckt hat.
    struct Hit: Equatable {
        var dealt: Double
        var absorbed: Double
        /// Der Schild eines Bosses hat alles geschluckt (P3-4).
        var shielded = false
    }

    /// Jeder Treffer läuft hier durch, damit Mondmal und Rüstung für alle Türme
    /// und den Steinregen an einer Stelle gelten. Erst die Rüstung, dann das Mal:
    /// Vor der Rüstung gerechnet, hob Mondmal die Elfen in Mission 4 über die
    /// Grenze der Völker (03). Die Fähigkeit durchschlägt Rüstung (P2-10, K7).
    /// `absorbed` ist in derselben Einheit wie `dealt`, also mit dem Mal.
    func strike(_ enemy: inout Enemy, by amount: Double, tick: Int, piercesArmor: Bool = false) -> Hit {
        if enemy.shieldUntilTick != nil { return Hit(dealt: 0, absorbed: 0, shielded: true) }
        var factor = 1.0
        if let mark = enemy.vulnerable, mark.untilTick > tick { factor = mark.factor }
        var passed = amount
        if !piercesArmor, let stats = config.enemies[enemy.kind],
           let armor = stats.armor, let share = stats.armorMinShare {
            passed = max(amount - armor, amount * share)
        }
        var dealt = passed * factor
        // Vor dem Schild hält der Boss an der Schwelle an, damit kein einzelner
        // schwerer Treffer die zweite Phase überspringt (P3-4).
        if let boss = config.enemies[enemy.kind]?.boss, enemy.shieldSpent != true {
            dealt = min(dealt, max(0, enemy.hp - boss.shieldAt * enemy.maxHP))
        }
        enemy.hp -= dealt
        return Hit(dealt: dealt, absorbed: (amount - passed) * factor)
    }

    func hurt(_ enemy: inout Enemy, by amount: Double, tick: Int, piercesArmor: Bool = false) -> Double {
        strike(&enemy, by: amount, tick: tick, piercesArmor: piercesArmor).dealt
    }

    /// Trifft und meldet; `armorAbsorbed` nur, wenn die Rüstung wirklich etwas
    /// geschluckt hat, damit Missionen ohne Rüstung dieselben Ereignisse liefern.
    /// `tower` ist der Index des schießenden Turms; er schreibt die Kampfbilanz
    /// (D-131). Gezählt wird nur, was am Leben ankam, und der Treffer, der es
    /// auf null bringt, ist der Sieg dieses Turms.
    private func damage(_ index: Int, by amount: Double, piercesArmor: Bool = false, tower: Int? = nil,
                        _ state: inout GameState, _ events: inout [Event]) {
        let before = state.enemies[index].hp
        let hit = strike(&state.enemies[index], by: amount, tick: state.tick, piercesArmor: piercesArmor)
        if let tower {
            state.towers[tower].damageDealt += min(hit.dealt, max(0, before))
            if before > 0 && state.enemies[index].hp <= 0 { state.towers[tower].kills += 1 }
        }
        let id = state.enemies[index].id
        if hit.shielded { return events.append(.shieldAbsorbed(id: id)) }
        events.append(.enemyDamaged(id: id, amount: hit.dealt))
        if hit.absorbed > 0 { events.append(.armorAbsorbed(id: id, amount: hit.absorbed)) }
    }

    /// Wie bei der Verlangsamung: der stärkste aktive Faktor, und ein neues Mal
    /// verkürzt ein laufendes nie.
    func applyVulnerable(_ mark: VulnerableEffect, to enemy: inout Enemy, tick: Int) {
        if let active = enemy.vulnerable, active.untilTick > tick {
            enemy.vulnerable = VulnerableEffect(factor: max(active.factor, mark.factor),
                                                untilTick: max(active.untilTick, mark.untilTick))
        } else {
            enemy.vulnerable = mark
        }
    }

    /// Abgerundet (Backlog WP-05). 90 × 0,7 ist in Double 62,999…; ohne den
    /// Schubs um wenige ulp käme 62 heraus statt 63.
    public func refund(for spent: Int) -> Int {
        let exact = Double(spent) * config.mission.sellRefundRate
        return Int((exact + exact.ulp * 4).rounded(.down))
    }

    private func startWaveIfDue(_ state: inout GameState, _ events: inout [Event]) {
        guard let due = state.nextWaveTick, state.tick >= due else { return }
        let index = state.waveIndex + 1
        let wave = config.waves[index]
        var planned: [(spawn: PendingSpawn, group: Int, number: Int)] = []
        for (group, spawnGroup) in wave.groups.enumerated() {
            let start = state.tick + ticks(spawnGroup.delay ?? 0)
            for number in 0..<spawnGroup.count {
                let tick = start + ticks(Double(number) * spawnGroup.interval)
                planned.append((PendingSpawn(tick: tick, enemy: spawnGroup.enemy, hpScale: wave.hpScale), group, number))
            }
        }
        // Gleicher Tick: Gruppe vor Gruppe, dann Nummer. Ausdrücklich, weil
        // `sort` keine Stabilität verspricht.
        planned.sort { ($0.spawn.tick, $0.group, $0.number) < ($1.spawn.tick, $1.group, $1.number) }
        state.pendingSpawns.append(contentsOf: planned.map(\.spawn))
        state.waveIndex = index
        // Der Takt läuft ab dem letzten Erscheinen, nicht ab dem letzten Tod
        // (01-core-gameplay.md, Wellentakt).
        let lastSpawn = planned.last?.spawn.tick ?? state.tick
        state.nextWaveTick = index + 1 < config.waves.count ? lastSpawn + ticks(config.mission.timeBetweenWaves) : nil
        events.append(.waveStarted(index: index))
    }

    private func spawnDue(_ state: inout GameState, _ events: inout [Event]) {
        var spawned = 0
        for pending in state.pendingSpawns {
            guard pending.tick <= state.tick else { break }
            guard let enemy = config.enemies[pending.enemy] else {
                preconditionFailure("BalanceConfig.validate lässt Wellen ohne Gegnerwerte nicht durch")
            }
            let hp = enemy.hp * pending.hpScale
            let id = state.nextEntityID
            state.nextEntityID += 1
            state.enemies.append(Enemy(id: id, kind: pending.enemy, hp: hp, maxHP: hp, distance: 0))
            events.append(.enemySpawned(id: id))
            spawned += 1
        }
        state.pendingSpawns.removeFirst(spawned)
    }

    private func fireTowers(_ state: inout GameState, _ events: inout [Event]) {
        for index in state.towers.indices {
            if state.towers[index].cooldownTicks > 0 { state.towers[index].cooldownTicks -= 1 }
            guard state.towers[index].cooldownTicks == 0 else { continue }
            let tower = state.towers[index]
            guard let stats = config.stats(of: tower) else { continue }
            switch tower.kind {
            case .bank:
                continue
            case .watch:
                let hits = targets(in: state.enemies, around: tower.cell.center, range: stats.range,
                                   mode: tower.targetMode, count: stats.targets ?? 1)
                guard !hits.isEmpty else { continue }
                // Erst der Schuss, dann die Treffer: wie bisher, nur über eine Stelle.
                events.append(.towerFired(towerID: tower.id, targets: hits.map { state.enemies[$0].id }))
                for hit in hits { damage(hit, by: stats.damage, tower: index, &state, &events) }
            case .lightning:
                guard let first = target(in: state.enemies, around: tower.cell.center, range: stats.range,
                                         mode: tower.targetMode)
                else { continue }
                let chain = chainTargets(in: state.enemies, from: first, stats: stats, tick: state.tick)
                events.append(.towerFired(towerID: tower.id, targets: chain.map { state.enemies[$0.index].id }))
                for hit in chain {
                    damage(hit.index, by: hit.damage, tower: index, &state, &events)
                }
            case .spore:
                let hits = enemiesInRange(state.enemies, around: tower.cell.center, range: stats.range)
                // Ohne Gegner kein Puls, damit der Turm bereit bleibt wie die anderen.
                guard !hits.isEmpty else { continue }
                events.append(.towerFired(towerID: tower.id, targets: hits.map { state.enemies[$0].id }))
                for hit in hits {
                    damage(hit, by: stats.damage, tower: index, &state, &events)
                    applySlow(to: &state.enemies[hit], stats: stats, tick: state.tick)
                    state.towers[index].slowHits += 1
                    // Fäulnis nach dem Schaden: Der Puls selbst trifft nicht stärker.
                    // Gleicher Zustand wie das Mondmal, also kein Stapeln mit ihm.
                    if let factor = stats.vulnerableFactor, let duration = stats.slowDuration {
                        applyVulnerable(VulnerableEffect(factor: factor, untilTick: state.tick + ticks(duration)),
                                        to: &state.enemies[hit], tick: state.tick)
                    }
                    events.append(.enemySlowed(id: state.enemies[hit].id))
                }
            }
            state.towers[index].cooldownTicks = ticks(stats.attackInterval)
        }
    }

    /// Zielwahl „erster": am weitesten auf dem Weg, bei Gleichstand der ältere.
    /// Schon tödlich getroffene Gegner zählen nicht, damit kein zweiter Turm im
    /// selben Tick seinen Schuss an einen Toten verschwendet.
    func firstTarget(in enemies: [Enemy], around center: Point, range: Double) -> Int? {
        target(in: enemies, around: center, range: range, mode: .first)
    }

    /// Erstes Ziel nach der Zielwahl des Turms (07, „Zielwahl“). Bei
    /// Gleichstand gewinnt immer der ältere Gegner (kleinere ID), weil die
    /// Liste nach ID sortiert ist und nur ein strikt besserer ersetzt.
    func target(in enemies: [Enemy], around center: Point, range: Double, mode: TargetMode) -> Int? {
        var best: Int?
        for (index, enemy) in enemies.enumerated() where enemy.hp > 0 {
            guard map.path.position(at: enemy.distance).distance(to: center) <= range else { continue }
            guard let current = best else {
                best = index
                continue
            }
            let other = enemies[current]
            let better = switch mode {
            case .first: enemy.distance > other.distance
            case .last: enemy.distance < other.distance
            // Nach Höchstleben, damit der Turm an der Panzerbestie bleibt; dann
            // wie „erster“.
            case .strongest: enemy.maxHP > other.maxHP || (enemy.maxHP == other.maxHP && enemy.distance > other.distance)
            }
            if better { best = index }
        }
        return best
    }

    /// Die besten `count` Ziele nach der Zielwahl, ohne doppelte (Salve, P3-1).
    /// Das erste ist dasselbe wie bei `target`, damit ein Ziel je Schuss sich
    /// nicht ändert.
    func targets(in enemies: [Enemy], around center: Point, range: Double, mode: TargetMode, count: Int) -> [Int] {
        // Der übliche Fall ohne Kopie: Wachtürme schießen jeden Takt.
        if count <= 1 { return target(in: enemies, around: center, range: range, mode: mode).map { [$0] } ?? [] }
        var remaining = enemies
        var found: [Int] = []
        while found.count < count, let next = target(in: remaining, around: center, range: range, mode: mode) {
            found.append(next)
            // Ausgeschlossen wie ein toter Gegner; die Indizes bleiben dieselben.
            remaining[next].hp = 0
        }
        return found
    }

    /// Kette des Blitzturms: vom ersten Ziel zum nächstgelegenen noch nicht
    /// getroffenen Gegner im Sprungradius, je Sprung um `chainFalloff` schwächer.
    /// Gemessen wird vom zuletzt getroffenen Gegner aus, nicht vom Turm. Mit
    /// Gewitterkrone verliert ein Sprung auf ein verlangsamtes Ziel nichts (P3-1).
    func chainTargets(in enemies: [Enemy], from first: Int, stats: TowerConfig,
                      tick: Int = 0) -> [(index: Int, damage: Double)] {
        let jumps = stats.chainJumps ?? 0
        let radius = stats.chainRadius ?? 0
        let falloff = stats.chainFalloff ?? 1
        let positions = enemies.map { map.path.position(at: $0.distance) }
        var hits: [(index: Int, damage: Double)] = [(first, stats.damage)]
        var damage = stats.damage
        var current = first
        let keepsOnSlowed = stats.keepsDamageOnSlowed ?? false
        for _ in 0..<jumps {
            var next: Int?, nextDistance = Double.infinity
            for (index, enemy) in enemies.enumerated() where enemy.hp > 0 && !hits.contains(where: { $0.index == index }) {
                let distance = positions[index].distance(to: positions[current])
                // Strikt kleiner: Bei gleichem Abstand bleibt der ältere (kleinere ID).
                if distance <= radius && distance < nextDistance {
                    next = index
                    nextDistance = distance
                }
            }
            guard let found = next else { break }
            let slowed = (enemies[found].slow?.untilTick ?? Int.min) > tick
            if !(keepsOnSlowed && slowed) { damage *= falloff }
            hits.append((found, damage))
            current = found
        }
        return hits
    }

    /// Alle lebenden Gegner in Reichweite, in Zustandsreihenfolge (nach ID).
    func enemiesInRange(_ enemies: [Enemy], around center: Point, range: Double) -> [Int] {
        enemies.indices.filter { index in
            enemies[index].hp > 0 && map.path.position(at: enemies[index].distance).distance(to: center) <= range
        }
    }

    /// Kein Stapeln (02-combat-and-towers.md): Es gilt die stärkste aktive
    /// Verlangsamung, und ein Puls verkürzt eine laufende nie. Sonst stünden
    /// Gegner unter fünf Sporentürmen still.
    func applySlow(to enemy: inout Enemy, stats: TowerConfig, tick: Int) {
        guard var factor = stats.slowFactor, let duration = stats.slowDuration else { return }
        if let scale = config.enemies[enemy.kind]?.slowScale { factor = 1 - (1 - factor) * scale }
        let until = tick + ticks(duration)
        if let active = enemy.slow, active.untilTick > tick {
            enemy.slow = SlowEffect(factor: min(active.factor, factor), untilTick: max(active.untilTick, until))
        } else {
            enemy.slow = SlowEffect(factor: factor, untilTick: until)
        }
    }

    /// Stehende Banken; eine verkaufte zählt nicht mehr.
    public func banks(in state: GameState) -> Int { state.towers.filter { $0.kind == .bank }.count }

    /// Gold, das Rufen der nächsten Welle jetzt brächte: eingesparte Sekunden
    /// mal `earlyCallBonus`, abgerundet. Öffentlich, damit der Welle-Knopf
    /// dieselbe Zahl zeigt, die die Simulation gutschreibt.
    public func earlyCallBonus(in state: GameState) -> Int {
        guard let rate = config.mission.earlyCallBonus, rate > 0, let due = state.nextWaveTick else { return 0 }
        let saved = Double(max(0, due - state.tick)) / Double(config.simulation.ticksPerSecond)
        // Wie beim Erstatten: 15 × 0,5 soll 7 ergeben, nicht 7 mit Rundungsrest darunter.
        let exact = saved * rate
        return Int((exact + exact.ulp * 4).rounded(.down))
    }

    /// Ertrag der Banken (04): ab `delay + interval` nach dem Bau alle
    /// `interval` Sekunden `payout`, bis der Deckel erreicht ist. Rein aus Tick
    /// und Bau-Tick, damit eine Wiederholung genau gleich zahlt.
    private func payBanks(_ state: inout GameState, _ events: inout [Event]) {
        guard let bank = config.bank else { return }
        let delay = ticks(bank.delay), interval = max(1, ticks(bank.interval))
        for index in state.towers.indices where state.towers[index].kind == .bank {
            let tower = state.towers[index]
            guard tower.paid < bank.cap else { continue }
            let elapsed = state.tick - tower.builtTick - delay
            guard elapsed > 0, elapsed % interval == 0 else { continue }
            let gold = min(bank.payout, bank.cap - tower.paid)
            state.gold += gold
            state.towers[index].paid += gold
            events.append(.bankPaid(towerID: tower.id, gold: gold, paid: state.towers[index].paid))
            if state.towers[index].paid >= bank.cap { events.append(.bankEmptied(towerID: tower.id)) }
        }
    }

    /// Schild heben, rufen, Schild fallen lassen (P3-4). Nach den Türmen, damit
    /// ein Boss, den sie an die Schwelle gebracht haben, im selben Tick stehen
    /// bleibt. Gerufene kommen hinten an die Liste, wie neu Erschienene.
    private func runBosses(_ state: inout GameState, _ events: inout [Event]) {
        let count = state.enemies.count
        for index in 0..<count {
            let enemy = state.enemies[index]
            guard let boss = config.enemies[enemy.kind]?.boss, enemy.hp > 0 else { continue }
            let duration = max(1, ticks(boss.shieldDuration))
            if enemy.shieldSpent != true, enemy.hp <= boss.shieldAt * enemy.maxHP {
                let until = state.tick + duration
                state.enemies[index].shieldUntilTick = until
                state.enemies[index].shieldSpent = true
                state.enemies[index].slow = nil
                events.append(.bossShieldRaised(id: enemy.id, untilTick: until))
            }
            guard let until = state.enemies[index].shieldUntilTick else { continue }
            if state.tick >= until {
                state.enemies[index].shieldUntilTick = nil
                events.append(.bossShieldDropped(id: enemy.id))
                continue
            }
            let elapsed = state.tick - (until - duration)
            guard elapsed % max(1, ticks(boss.summonEvery)) == 0, let stats = config.enemies[boss.summon] else { continue }
            let hp = stats.hp * boss.summonHPScale
            var summoned: [Int] = []
            for _ in 0..<boss.summonCount {
                let id = state.nextEntityID
                state.nextEntityID += 1
                state.enemies.append(Enemy(id: id, kind: boss.summon, hp: hp, maxHP: hp, distance: enemy.distance))
                events.append(.enemySpawned(id: id))
                summoned.append(id)
            }
            events.append(.bossSummoned(id: enemy.id, summoned: summoned))
        }
    }

    private func collectKills(_ state: inout GameState, _ events: inout [Event]) {
        var alive: [Enemy] = []
        for enemy in state.enemies {
            guard enemy.hp <= 0 else {
                alive.append(enemy)
                continue
            }
            let reward = config.enemies[enemy.kind]?.reward ?? 0
            state.gold += reward
            events.append(.enemyKilled(id: enemy.id, reward: reward))
        }
        state.enemies = alive
    }

    private func move(_ state: inout GameState) {
        let perTick = 1 / Double(config.simulation.ticksPerSecond)
        for index in state.enemies.indices {
            guard let enemy = config.enemies[state.enemies[index].kind] else { continue }
            if state.enemies[index].shieldUntilTick != nil { continue }
            if let stun = state.enemies[index].stunUntilTick {
                if stun > state.tick { continue }
                state.enemies[index].stunUntilTick = nil
            }
            if let mark = state.enemies[index].vulnerable, mark.untilTick <= state.tick {
                state.enemies[index].vulnerable = nil
            }
            var factor = 1.0
            if let slow = state.enemies[index].slow {
                if slow.untilTick > state.tick { factor = slow.factor } else { state.enemies[index].slow = nil }
            }
            let before = state.enemies[index].distance
            var next = before + enemy.speed * factor * perTick
            // Wer vor der Mauer ist, kommt bis an sie heran und nicht weiter; wer
            // schon dahinter ist, läuft weiter (r-4-voelker.md).
            if let barrier = state.ability.barrier, before <= barrier.distance { next = min(next, barrier.distance) }
            state.enemies[index].distance = next
        }
    }

    /// Sieg (01-core-gameplay.md): alle Wellen erschienen, niemand lebt mehr.
    /// Läuft nach den Durchbrüchen, damit ein Durchbruch im letzten Tick zuerst
    /// zählt; hat er die Festung geleert, ist die Mission schon verloren.
    private func checkVictory(_ state: inout GameState, _ events: inout [Event]) {
        guard state.outcome == nil, state.nextWaveTick == nil,
              state.pendingSpawns.isEmpty, state.enemies.isEmpty else { return }
        state.outcome = .won
        events.append(.missionEnded(won: true))
    }

    private func leak(_ state: inout GameState, _ events: inout [Event]) {
        var remaining: [Enemy] = []
        for (position, enemy) in state.enemies.enumerated() {
            guard enemy.distance >= map.path.length else {
                remaining.append(enemy)
                continue
            }
            let damage = config.enemies[enemy.kind]?.leakDamage ?? 0
            state.fortressLives = max(0, state.fortressLives - damage)
            events.append(.enemyLeaked(id: enemy.id, damage: damage))
            if state.fortressLives == 0 {
                // Die Mission endet sofort (01-core-gameplay.md): Wer im selben
                // Tick noch durchgebrochen wäre, zählt nicht mehr.
                remaining.append(contentsOf: state.enemies[(position + 1)...])
                state.enemies = remaining
                state.outcome = .lost
                events.append(.missionEnded(won: false))
                return
            }
        }
        state.enemies = remaining
    }
}
