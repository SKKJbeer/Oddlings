import Foundation

/// Eine laufende Mission, gesichert, als die App in den Hintergrund ging (P2-2,
/// D-022, D-074). Steht im Spielstand, damit Fortschritt und laufende Mission in
/// einer Datei atomar geschrieben werden und nie auseinanderlaufen.
public struct SuspendedBattle: Codable, Equatable, Sendable {
    /// Kampagnenknoten der Mission.
    public var node: String
    /// Fingerabdruck der gespielten Konfiguration (`BalanceConfig.fingerprint`).
    /// Passt er beim Laden nicht mehr, wäre der Zustand ein Spiel unter Regeln,
    /// die es so nie gab: Die Mission beginnt dann neu.
    public var rules: String
    /// Startwert, damit „Neu starten“ in der fortgesetzten Mission dieselbe
    /// Mission beginnt wie vorher.
    public var seed: UInt64
    public var state: GameState

    public init(node: String, rules: String, seed: UInt64, state: GameState) {
        self.node = node
        self.rules = rules
        self.seed = seed
        self.state = state
    }

    /// Was am Zustand nicht zu dieser Mission passt; leer heißt, die Simulation
    /// darf ihn übernehmen. Der Zustand kommt aus einer Datei und damit von
    /// außen (Sicherheitsregel). Geprüft wird, worauf sich `step` verlässt; ein
    /// Fund verwirft die Mission, nie den Fortschritt.
    public func problems(for sim: Simulation) -> [String] {
        let config = sim.config
        let s = state
        var found: [String] = []
        func check(_ ok: Bool, _ text: @autoclosure () -> String) { if !ok { found.append(text()) } }

        check(s.outcome == nil, "Mission ist schon entschieden")
        check(s.tick >= 0, "Tick \(s.tick)")
        check(s.gold >= 0, "Gold \(s.gold)")
        check((1...max(1, config.mission.fortressLives)).contains(s.fortressLives), "Leben \(s.fortressLives)")
        check((-1..<config.waves.count).contains(s.waveIndex), "Welle \(s.waveIndex)")
        if let next = s.nextWaveTick { check(next >= 0, "nächste Welle \(next)") }
        check(s.nextEntityID >= 1, "nächste Kennung \(s.nextEntityID)")

        for spawn in s.pendingSpawns {
            check(config.enemies[spawn.enemy] != nil, "Gegnerart \(spawn.enemy.rawValue) fehlt in der Mission")
            check(spawn.tick >= s.tick, "Erscheinen in der Vergangenheit (\(spawn.tick))")
            check(spawn.hpScale.isFinite && spawn.hpScale > 0, "Lebensfaktor \(spawn.hpScale)")
        }

        var ids: [Int] = []
        var cells: [Cell] = []
        for tower in s.towers {
            ids.append(tower.id)
            check(config.cost(of: tower.kind) != nil, "Turmart \(tower.kind.rawValue) fehlt in der Mission")
            check(sim.map.isBuildable(tower.cell), "Turm \(tower.id) steht nicht auf einem Bauplatz")
            check(!cells.contains(tower.cell), "zwei Türme auf \(tower.cell.x),\(tower.cell.y)")
            cells.append(tower.cell)
            // Stufe 3 genau mit einer Spezialisierung, die die Mission dem Turm anbietet (P3-1).
            if let specialization = tower.specialization {
                check(tower.level == 3 && config.specializations(for: tower.kind).contains(specialization),
                      "Spezialisierung \(specialization.rawValue) auf Stufe \(tower.level)")
            } else {
                check((1...config.maxLevel(of: tower.kind)).contains(tower.level), "Stufe \(tower.level)")
            }
            check(tower.cooldownTicks >= 0 && tower.spent >= 0 && tower.paid >= 0, "Turm \(tower.id) mit negativen Werten")
            check(tower.builtTick >= 0 && tower.builtTick <= s.tick, "Bauzeit \(tower.builtTick)")
        }
        let length = sim.map.path.length
        for enemy in s.enemies {
            ids.append(enemy.id)
            check(config.enemies[enemy.kind] != nil, "Gegnerart \(enemy.kind.rawValue) fehlt in der Mission")
            check(enemy.maxHP.isFinite && enemy.maxHP > 0, "Gegner \(enemy.id) Höchstleben \(enemy.maxHP)")
            check(enemy.hp.isFinite && enemy.hp > 0 && enemy.hp <= enemy.maxHP, "Gegner \(enemy.id) Leben \(enemy.hp)")
            check(enemy.distance.isFinite && enemy.distance >= 0 && enemy.distance <= length,
                  "Gegner \(enemy.id) Weg \(enemy.distance)")
            if let slow = enemy.slow { check(slow.factor.isFinite && slow.factor > 0, "Verlangsamung \(slow.factor)") }
            if let mark = enemy.vulnerable { check(mark.factor.isFinite && mark.factor > 0, "Mondmal \(mark.factor)") }
        }
        check(ids.allSatisfy { $0 >= 1 && $0 < s.nextEntityID }, "Kennung außerhalb 1..<\(s.nextEntityID)")
        let sorted = ids.sorted()
        check(zip(sorted, sorted.dropFirst()).allSatisfy { $0 != $1 }, "doppelte Kennung")

        if config.ability == nil {
            check(s.ability.strike == nil && s.ability.barrier == nil, "Fähigkeit ohne Fähigkeit der Mission")
        }
        if let strike = s.ability.strike {
            check(strike.center.x.isFinite && strike.center.y.isFinite, "Ziel der Fähigkeit")
            check(strike.impactTick >= s.tick, "Einschlag in der Vergangenheit")
        }
        if let barrier = s.ability.barrier {
            check(barrier.distance.isFinite && barrier.distance >= 0 && barrier.distance <= length, "Mauer \(barrier.distance)")
        }
        return found
    }
}

extension BalanceConfig {
    /// Fingerabdruck der Regeln, mit denen eine Mission gespielt wird. Verglichen
    /// wird nur auf demselben Gerät (gesicherte Mission gegen die App nach einem
    /// Neustart), deshalb genügt JSON mit sortierten Schlüsseln: Alle Tabellen
    /// haben Aufzählungen als Schlüssel und werden als Objekte geschrieben, nie in
    /// Hash-Reihenfolge. 16 Hexziffern als Text, weil JSON-Zahlen über 2⁵³ nicht
    /// überall genau ankommen.
    public var fingerprint: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        // Kodieren scheitert nur an unendlichen Zahlen, die die Prüfung beim
        // Laden schon abweist; dann gilt ein Abdruck, der zu nichts passt.
        guard let data = try? encoder.encode(self) else { return "" }
        var sum = Checksum()
        for byte in data { sum.add(UInt64(byte)) }
        return String(format: "%016llx", sum.value)
    }
}
