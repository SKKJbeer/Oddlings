import Foundation

/// Prüfsumme eines Zustands für Replays und Determinismustests (WP-10).
/// Von Hand über die Felder statt über JSON, weil JSONEncoder Kommazahlen je
/// Plattform anders schreiben darf; die Bitmuster der Doubles sind dagegen
/// überall gleich. FNV-1a, weil es klein ist und ohne Abhängigkeit auskommt.
public struct Checksum: Equatable, Sendable {
    public private(set) var value: UInt64 = 0xCBF2_9CE4_8422_2325

    public init() {}

    mutating func add(_ word: UInt64) {
        for shift in stride(from: 0, to: 64, by: 8) {
            value ^= (word >> UInt64(shift)) & 0xFF
            value &*= 0x0000_0100_0000_01B3
        }
    }

    mutating func add(_ number: Int) { add(UInt64(bitPattern: Int64(number))) }
    mutating func add(_ number: Double) { add(number.bitPattern) }
    mutating func add(_ text: String) {
        add(text.utf8.count)
        for byte in text.utf8 { add(UInt64(byte)) }
    }
    /// Kennung vor optionalen Werten, damit `nil` und 0 verschieden zählen.
    mutating func add(_ number: Int?) {
        if let number { add(1); add(number) } else { add(0) }
    }
}

extension GameState {
    public var checksum: UInt64 {
        var sum = Checksum()
        sum.add(tick)
        sum.add(gold)
        sum.add(fortressLives)
        sum.add(waveIndex)
        sum.add(nextWaveTick)
        sum.add(pendingSpawns.count)
        for spawn in pendingSpawns {
            sum.add(spawn.tick)
            sum.add(spawn.enemy.rawValue)
            sum.add(spawn.hpScale)
        }
        sum.add(towers.count)
        for tower in towers {
            sum.add(tower.id)
            sum.add(tower.kind.rawValue)
            sum.add(tower.cell.x)
            sum.add(tower.cell.y)
            sum.add(tower.cooldownTicks)
            sum.add(tower.spent)
        }
        sum.add(enemies.count)
        for enemy in enemies {
            sum.add(enemy.id)
            sum.add(enemy.kind.rawValue)
            sum.add(enemy.hp)
            sum.add(enemy.maxHP)
            sum.add(enemy.distance)
            if let slow = enemy.slow {
                sum.add(1)
                sum.add(slow.factor)
                sum.add(slow.untilTick)
            } else {
                sum.add(0)
            }
            sum.add(enemy.stunUntilTick)
            if let vulnerable = enemy.vulnerable {
                sum.add(1)
                sum.add(vulnerable.factor)
                sum.add(vulnerable.untilTick)
            } else {
                sum.add(0)
            }
        }
        sum.add(ability.readyTick)
        if let strike = ability.strike {
            sum.add(1)
            sum.add(strike.center.x)
            sum.add(strike.center.y)
            sum.add(strike.impactTick)
        } else {
            sum.add(0)
        }
        if let barrier = ability.barrier {
            sum.add(1)
            sum.add(barrier.distance)
            sum.add(barrier.untilTick)
        } else {
            sum.add(0)
        }
        sum.add(nextEntityID)
        sum.add(outcome?.rawValue ?? "")
        sum.add(rng.state)
        return sum.value
    }
}
