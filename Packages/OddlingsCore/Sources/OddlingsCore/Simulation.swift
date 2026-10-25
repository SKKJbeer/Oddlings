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
    /// ändert (data-models.md): Wellen/Spawns → Bewegung → Durchbrüche → Ende.
    /// Befehle, Türme und Gold folgen mit WP-05 und WP-06 an ihren Platz davor.
    @discardableResult
    public func step(_ state: inout GameState) -> [Event] {
        guard !state.isOver else { return [] }
        var events: [Event] = []
        startWaveIfDue(&state, &events)
        spawnDue(&state, &events)
        move(&state)
        leak(&state, &events)
        state.tick += 1
        return events
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

    private func move(_ state: inout GameState) {
        let perTick = 1 / Double(config.simulation.ticksPerSecond)
        for index in state.enemies.indices {
            guard let enemy = config.enemies[state.enemies[index].kind] else { continue }
            state.enemies[index].distance += enemy.speed * perTick
        }
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
