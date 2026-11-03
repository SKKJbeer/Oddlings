import Foundation

/// Alle Werte einer Mission. Unveränderlich, kommt ausschließlich aus JSON
/// (Architekturregel 7): Wer eine Zahl ändern will, ändert die Datei.
public struct BalanceConfig: Codable, Equatable, Sendable {
    public var simulation: SimulationConfig
    public var mission: MissionConfig
    public var map: MapConfig
    /// Nur zum Nachschlagen. Die Simulation iteriert nie über diese Tabelle
    /// (Architekturregel 6), sondern über `TowerKind.allCases`.
    public var towers: [TowerKind: TowerConfig]
    public var enemies: [EnemyKind: EnemyConfig]
    public var waves: [WaveConfig]
    /// Bauweisen für Balancetests und Vorführung, keine Spielregel: Die
    /// Simulation liest sie nie. Nach Namen nachschlagen, nie darüber iterieren.
    public var simStrategies: [String: [StrategyStep]]?
    /// Name der Bauweise, mit der der Mitspieler die Mission vorführt.
    public var demoStrategy: String?
    /// Festungsfähigkeit der Mission (D-025). Fehlt sie, gibt es keinen Knopf,
    /// und die Simulation lehnt den Befehl ab.
    public var ability: AbilityConfig?
    /// Zwergenbank (D-026, P2-5). Fehlt sie, bietet die Mission keine Bank an,
    /// und die Simulation lehnt den Bau ab.
    public var bank: BankConfig?
    /// Aufwertung auf Stufe 2 je Kampfturm (D-024, P2-6). Fehlt der Abschnitt,
    /// bietet die Mission keine Aufwertung an, und die Simulation lehnt sie ab.
    /// Nur zum Nachschlagen, nie darüber iterieren (Architekturregel 6).
    public var upgrades: [TowerKind: UpgradeConfig]?
    /// Spezialisierungen auf Stufe 3 (D-024, P3-1). Fehlt der Abschnitt, ist
    /// Stufe 2 die höchste. Nur zum Nachschlagen; gefragt wird über
    /// `specializations(for:)`, das `Specialization.allCases` durchgeht (Regel 6).
    public var specializations: [Specialization: SpecializationConfig]?

    public init(
        simulation: SimulationConfig, mission: MissionConfig, map: MapConfig,
        towers: [TowerKind: TowerConfig], enemies: [EnemyKind: EnemyConfig], waves: [WaveConfig],
        simStrategies: [String: [StrategyStep]]? = nil, demoStrategy: String? = nil,
        ability: AbilityConfig? = nil, bank: BankConfig? = nil, upgrades: [TowerKind: UpgradeConfig]? = nil,
        specializations: [Specialization: SpecializationConfig]? = nil
    ) {
        self.simulation = simulation
        self.mission = mission
        self.map = map
        self.towers = towers
        self.enemies = enemies
        self.waves = waves
        self.simStrategies = simStrategies
        self.demoStrategy = demoStrategy
        self.ability = ability
        self.bank = bank
        self.upgrades = upgrades
        self.specializations = specializations
    }

    /// Was die Mission zu bauen anbietet, in fester Reihenfolge: die
    /// Kampftürme, dazu die Bank, wenn die Mission sie hat. Die Oberfläche
    /// fragt nur hier, nie die Tabellen direkt.
    public var buildable: [TowerKind] { TowerKind.combat + (bank == nil ? [] : [.bank]) }

    /// Baupreis einer Turmart, nil, wenn die Mission sie nicht anbietet.
    public func cost(of kind: TowerKind) -> Int? {
        kind == .bank ? bank?.cost : towers[kind]?.cost
    }

    /// Preis der Aufwertung, nil, wenn die Mission diese Turmart nicht aufwertet.
    public func upgradeCost(of kind: TowerKind) -> Int? { upgrades?[kind]?.cost }

    /// Höchste Stufe eines Turms in dieser Mission: 2, wenn es für seine Art
    /// eine Aufwertung gibt, sonst 1.
    public func maxLevel(of kind: TowerKind) -> Int { upgrades?[kind] == nil ? 1 : 2 }

    /// Die Werte, mit denen ein Turm auf seiner Stufe kämpft. Die einzige
    /// Stelle, die Stufe 2 rechnet: Simulation, Bot und App fragen hier.
    /// Stufe 2 multipliziert die Werte der Stufe 1 aus dieser Konfiguration,
    /// damit Boni von Volk und Ausrüstung beim Aufwerten erhalten bleiben.
    public func stats(of kind: TowerKind, level: Int) -> TowerConfig? {
        guard let base = towers[kind] else { return nil }
        guard level >= 2, let upgrade = upgrades?[kind] else { return base }
        return upgrade.apply(to: base)
    }

    /// Werte auf Stufe 3: die Spezialisierung auf den Werten der Stufe 2, wie
    /// Stufe 2 auf denen der Stufe 1 (D-084). Nil, wenn die Mission sie nicht
    /// anbietet oder sie zu einem anderen Turm gehört.
    public func stats(of kind: TowerKind, specialization: Specialization) -> TowerConfig? {
        guard specialization.tower == kind, let special = specializations?[specialization],
              let second = stats(of: kind, level: 2) else { return nil }
        return special.apply(to: second)
    }

    public func stats(of tower: Tower) -> TowerConfig? {
        if let specialization = tower.specialization { return stats(of: tower.kind, specialization: specialization) }
        return stats(of: tower.kind, level: tower.level)
    }

    /// Was ein Turm dieser Art auf Stufe 2 werden kann, in fester Reihenfolge.
    /// Leer ohne Aufwertung: Stufe 3 setzt Stufe 2 voraus.
    public func specializations(for kind: TowerKind) -> [Specialization] {
        guard upgrades?[kind] != nil, let offered = specializations else { return [] }
        return Specialization.allCases.filter { $0.tower == kind && offered[$0] != nil }
    }
}

/// Stufe 3 eines Kampfturms (02, „Spezialisierungen“). Jede gehört zu genau
/// einem Turm; das steht hier und nicht in der Datei, weil eine Salve am
/// Sporenturm keine Wertfrage ist. Sumpfpfad (P3-1) und Ruinen (P3-2) je drei.
public enum Specialization: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    /// Salve: trifft mehrere Ziele je Schuss.
    case volley
    /// Gewitterkrone: weitere Sprünge, kein Abfall auf verlangsamten Zielen.
    case stormCrown
    /// Moorherz: größerer Radius, stärkere Verlangsamung.
    case bogHeart
    /// Falkenhorst: große Reichweite, schwerer Schuss, langsamer.
    case falconHold
    /// Funkensäule: erster Treffer stärker, weniger Sprünge.
    case sparkColumn
    /// Fäulnis: Verlangsamte nehmen von allen Türmen mehr Schaden.
    case rot

    public var tower: TowerKind {
        switch self {
        case .volley, .falconHold: .watch
        case .stormCrown, .sparkColumn: .lightning
        case .bogHeart, .rot: .spore
        }
    }
}

/// Preis und Wirkung einer Spezialisierung, gerechnet auf den Werten der Stufe 2.
public struct SpecializationConfig: Codable, Equatable, Sendable {
    public var cost: Int
    /// Faktoren wie bei der Aufwertung; nur zum Nachschlagen.
    public var scale: [TowerStat: Double]?
    /// Ziele je Schuss (Salve). Ersetzt die eins des Wachturms.
    public var targets: Int?
    /// Sprünge zusätzlich zur Kette der Stufe 2 (Gewitterkrone mehr,
    /// Funkensäule weniger). Die Kette bleibt bei mindestens null.
    public var extraJumps: Int?
    /// Sprünge auf verlangsamte Ziele verlieren keinen Schaden (Gewitterkrone).
    public var keepsDamageOnSlowed: Bool?
    /// Schadensfaktor auf alles, was der Sporenpuls verlangsamt (Fäulnis, P3-2).
    public var vulnerableFactor: Double?

    public init(cost: Int, scale: [TowerStat: Double]? = nil, targets: Int? = nil, extraJumps: Int? = nil,
                keepsDamageOnSlowed: Bool? = nil, vulnerableFactor: Double? = nil) {
        self.cost = cost
        self.scale = scale
        self.targets = targets
        self.extraJumps = extraJumps
        self.keepsDamageOnSlowed = keepsDamageOnSlowed
        self.vulnerableFactor = vulnerableFactor
    }

    public func apply(to second: TowerConfig) -> TowerConfig {
        var tower = UpgradeConfig(cost: cost, scale: scale ?? [:]).apply(to: second)
        if let targets { tower.targets = targets }
        if let extraJumps { tower.chainJumps = (tower.chainJumps ?? 0) + extraJumps }
        if let keepsDamageOnSlowed { tower.keepsDamageOnSlowed = keepsDamageOnSlowed }
        if let vulnerableFactor { tower.vulnerableFactor = vulnerableFactor }
        return tower
    }
}

/// Ein Wert eines Kampfturms, den eine Aufwertung skalieren darf.
public enum TowerStat: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case range, damage, attackInterval, chainRadius, slowFactor, slowDuration
}

/// Aufwertung auf Stufe 2 (02, „Aufwertungen“): Preis und Faktoren auf die
/// Werte der Stufe 1. Faktoren statt fester Werte, weil Volk und Ausrüstung
/// die Stufe 1 schon verändert haben (D-084).
public struct UpgradeConfig: Codable, Equatable, Sendable {
    public var cost: Int
    /// Nur zum Nachschlagen; `apply` geht über `TowerStat.allCases`.
    public var scale: [TowerStat: Double]

    public init(cost: Int, scale: [TowerStat: Double]) {
        self.cost = cost
        self.scale = scale
    }

    public func apply(to base: TowerConfig) -> TowerConfig {
        var tower = base
        for stat in TowerStat.allCases {
            guard let factor = scale[stat] else { continue }
            switch stat {
            case .range: tower.range *= factor
            case .damage: tower.damage *= factor
            case .attackInterval: tower.attackInterval *= factor
            case .chainRadius: tower.chainRadius = tower.chainRadius.map { $0 * factor }
            case .slowFactor: tower.slowFactor = tower.slowFactor.map { $0 * factor }
            case .slowDuration: tower.slowDuration = tower.slowDuration.map { $0 * factor }
            }
        }
        return tower
    }
}

/// Ein Schritt einer Bauweise der Balancetests und des Mitspielers: einen
/// Turm bauen oder den ältesten Turm einer Art auf Stufe 1 aufwerten. In der
/// Datei `"watch"` bzw. `"watch+"`, damit Bauweisen lesbar bleiben und alte
/// Dateien gültig.
public enum StrategyStep: Equatable, Sendable, Codable {
    case build(TowerKind)
    case upgrade(TowerKind)
    /// Spezialisiert den ältesten passenden Turm auf Stufe 2 (P3-1). In der
    /// Datei der Name der Spezialisierung, etwa `"volley"`.
    case specialize(Specialization)

    public var kind: TowerKind {
        switch self {
        case .build(let kind), .upgrade(let kind): kind
        case .specialize(let specialization): specialization.tower
        }
    }

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        if let specialization = Specialization(rawValue: text) {
            self = .specialize(specialization)
            return
        }
        let upgrade = text.hasSuffix("+")
        guard let kind = TowerKind(rawValue: upgrade ? String(text.dropLast()) : text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "Unbekannter Schritt \(text)"))
        }
        self = upgrade ? .upgrade(kind) : .build(kind)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .build(let kind): try container.encode(kind.rawValue)
        case .upgrade(let kind): try container.encode(kind.rawValue + "+")
        case .specialize(let specialization): try container.encode(specialization.rawValue)
        }
    }
}

/// Werte der Zwergenbank (04, „Zwergenbank“). Eigener Typ statt `TowerConfig`:
/// Eine Bank hat keine Reichweite, keinen Schaden und keinen Takt, und ein Typ
/// mit Feldern, die für ihn nichts bedeuten, lädt zu Fehlern ein.
public struct BankConfig: Codable, Equatable, Sendable {
    public var cost: Int
    /// Sekunden ab Bau bis zum Beginn des Ertrags. Die erste Auszahlung kommt
    /// nach `delay + interval`.
    public var delay: Double
    /// Sekunden zwischen zwei Auszahlungen
    public var interval: Double
    /// Gold je Auszahlung
    public var payout: Int
    /// Gold, das eine Bank insgesamt auszahlt
    public var cap: Int
    /// Höchstzahl gleichzeitig stehender Banken je Mission
    public var limit: Int

    public init(cost: Int, delay: Double, interval: Double, payout: Int, cap: Int, limit: Int) {
        self.cost = cost
        self.delay = delay
        self.interval = interval
        self.payout = payout
        self.cap = cap
        self.limit = limit
    }
}

/// Welche Festungsfähigkeit (03, „Eine aktive Festungsfähigkeit"). Das Volk
/// bestimmt sie (R-4), die Simulation fragt nur nach der Art, nie nach dem Volk.
public enum AbilityKind: String, Codable, CaseIterable, Sendable {
    /// Wurf auf eine Stelle am Weg: nach `delay` Schaden und Anhalten im Kreis.
    case stoneRain
    /// Mauer quer zum Weg: Wer sie erreicht, steht, bis sie nach `duration` fällt.
    case bulwark
    /// Mal auf eine Stelle: nach `delay` nehmen Getroffene `duration` lang
    /// jeden Treffer mal `damageFactor`.
    case moonMark
}

/// Werte einer Festungsfähigkeit. Ein Typ für alle Arten, die Felder einer Art
/// sind optional; `issues()` verlangt genau die, die die Art braucht. Ein
/// eigener Typ je Art wäre bei drei Arten mehr Code als Nutzen (wie `TowerConfig`).
public struct AbilityConfig: Codable, Equatable, Sendable {
    public var kind: AbilityKind
    /// Sekunden ab dem Wurf bis zur nächsten Bereitschaft
    public var cooldown: Double
    /// So viele Felder darf der Wurf neben dem Weg liegen; er wird auf den Weg gezogen.
    public var snapDistance: Double
    /// Felder (Steinregen, Mondmal)
    public var radius: Double?
    /// Steinregen
    public var damage: Double?
    /// Sekunden vom Wurf bis zur Wirkung (Steinregen, Mondmal)
    public var delay: Double?
    /// Sekunden, die Getroffene stehen (Steinregen)
    public var stunDuration: Double?
    /// Sekunden, die Mauer oder Mal halten (Bollwerk, Mondmal)
    public var duration: Double?
    /// Faktor auf jeden Treffer, größer als 1 (Mondmal)
    public var damageFactor: Double?

    public init(kind: AbilityKind, cooldown: Double, snapDistance: Double, radius: Double? = nil,
                damage: Double? = nil, delay: Double? = nil, stunDuration: Double? = nil,
                duration: Double? = nil, damageFactor: Double? = nil) {
        self.kind = kind
        self.cooldown = cooldown
        self.snapDistance = snapDistance
        self.radius = radius
        self.damage = damage
        self.delay = delay
        self.stunDuration = stunDuration
        self.duration = duration
        self.damageFactor = damageFactor
    }

    /// Steinregen, wie bis 0.8.0 die einzige Fähigkeit.
    public init(radius: Double, damage: Double, delay: Double, stunDuration: Double,
                cooldown: Double, snapDistance: Double) {
        self.init(kind: .stoneRain, cooldown: cooldown, snapDistance: snapDistance, radius: radius,
                  damage: damage, delay: delay, stunDuration: stunDuration)
    }

    private enum CodingKeys: String, CodingKey {
        case kind, cooldown, snapDistance, radius, damage, delay, stunDuration, duration, damageFactor
    }

    /// Fehlt `kind`, ist es Steinregen: Missionsdateien von 0.8.0 bleiben gültig.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decodeIfPresent(AbilityKind.self, forKey: .kind) ?? .stoneRain
        cooldown = try c.decode(Double.self, forKey: .cooldown)
        snapDistance = try c.decode(Double.self, forKey: .snapDistance)
        radius = try c.decodeIfPresent(Double.self, forKey: .radius)
        damage = try c.decodeIfPresent(Double.self, forKey: .damage)
        delay = try c.decodeIfPresent(Double.self, forKey: .delay)
        stunDuration = try c.decodeIfPresent(Double.self, forKey: .stunDuration)
        duration = try c.decodeIfPresent(Double.self, forKey: .duration)
        damageFactor = try c.decodeIfPresent(Double.self, forKey: .damageFactor)
    }
}

public struct SimulationConfig: Codable, Equatable, Sendable {
    public var ticksPerSecond: Int
    public init(ticksPerSecond: Int) { self.ticksPerSecond = ticksPerSecond }
}

public struct MissionConfig: Codable, Equatable, Sendable {
    public var id: String
    public var fortressLives: Int
    public var startGold: Int
    /// Sekunden
    public var firstWaveDelay: Double
    /// Sekunden
    public var timeBetweenWaves: Double
    public var sellRefundRate: Double
    /// Fehlt sie, gibt jeder Sieg einen Stern. Optional, damit Regeltests
    /// ohne Kampagne auskommen.
    public var stars: StarThresholds?
    /// Gold je eingesparter Sekunde, wenn die nächste Welle früher gerufen
    /// wird (D-009, E8). Fehlt er, gibt es keinen Bonus.
    public var earlyCallBonus: Double?

    public init(
        id: String, fortressLives: Int, startGold: Int,
        firstWaveDelay: Double, timeBetweenWaves: Double, sellRefundRate: Double,
        stars: StarThresholds? = nil, earlyCallBonus: Double? = nil
    ) {
        self.id = id
        self.fortressLives = fortressLives
        self.startGold = startGold
        self.firstWaveDelay = firstWaveDelay
        self.timeBetweenWaves = timeBetweenWaves
        self.sellRefundRate = sellRefundRate
        self.stars = stars
        self.earlyCallBonus = earlyCallBonus
    }
}

/// Wie viele Leben nach dem Sieg für zwei und drei Sterne übrig sein müssen (05).
public struct StarThresholds: Codable, Equatable, Sendable {
    public var two: Int
    public var three: Int

    public init(two: Int, three: Int) {
        self.two = two
        self.three = three
    }
}

public struct MapConfig: Codable, Equatable, Sendable {
    public var width: Int
    public var height: Int
    /// Mindestabstand einer Zellmitte zum Weg, damit dort gebaut werden darf.
    public var minDistanceFromPath: Double
    public var path: [Point]

    public init(width: Int, height: Int, minDistanceFromPath: Double, path: [Point]) {
        self.width = width
        self.height = height
        self.minDistanceFromPath = minDistanceFromPath
        self.path = path
    }
}

/// Punkt in Feldern. Im JSON als `[x, y]`, weil die Wegliste sonst unlesbar lang wird.
public struct Point: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        x = try container.decode(Double.self)
        y = try container.decode(Double.self)
        if !container.isAtEnd {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Ein Punkt hat genau zwei Koordinaten.")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}

public enum TowerKind: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case watch, lightning, spore
    /// Zwergenbank: kein Kampf, Ertrag nach Verzögerung (D-026).
    case bank

    /// Die Türme, die kämpfen und in `towers` stehen. Feuern und Prüfung laufen
    /// nur über sie.
    public static let combat: [TowerKind] = [.watch, .lightning, .spore]
}

public enum EnemyKind: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case raider, runner, brute
}

/// Wen ein Turm mit Einzelziel zuerst nimmt (07, „Zielwahl“). Wählbar ab
/// Stufe 2; bis dahin und ohne Wahl gilt `first`.
public enum TargetMode: String, Codable, CaseIterable, Sendable {
    /// Am weitesten auf dem Weg.
    case first
    /// Am wenigsten weit auf dem Weg.
    case last
    /// Größtes Höchstleben: die zäheste Art, nicht der gerade vollste.
    case strongest

    /// Reihenfolge des Knopfs: Erster → Letzter → Stärkster → Erster.
    public var next: TargetMode {
        switch self {
        case .first: .last
        case .last: .strongest
        case .strongest: .first
        }
    }
}

public enum Targeting: String, Codable, Sendable {
    /// Der Gegner, der am weitesten auf dem Weg ist.
    case first
    /// Alle in Reichweite gleichzeitig.
    case aura
}

/// Ein Typ für alle Türme, die Rollen über optionale Felder. Reicht für drei
/// Türme; umgebaut wird erst, wenn der vierte Rollentyp es verlangt (data-models.md).
public struct TowerConfig: Codable, Equatable, Sendable {
    public var cost: Int
    public var range: Double
    public var damage: Double
    /// Sekunden
    public var attackInterval: Double
    public var targeting: Targeting
    public var chainJumps: Int?
    public var chainRadius: Double?
    public var chainFalloff: Double?
    public var slowFactor: Double?
    /// Sekunden
    public var slowDuration: Double?
    /// Ziele je Schuss eines Einzelziel-Turms; fehlt es, eines (Salve, P3-1).
    public var targets: Int?
    /// Kettensprünge auf verlangsamte Ziele ohne Abfall (Gewitterkrone, P3-1).
    public var keepsDamageOnSlowed: Bool?
    /// Der Puls macht verlangsamte Gegner für die Dauer der Verlangsamung
    /// verwundbar (Fäulnis, P3-2).
    public var vulnerableFactor: Double?

    public init(
        cost: Int, range: Double, damage: Double, attackInterval: Double, targeting: Targeting,
        chainJumps: Int? = nil, chainRadius: Double? = nil, chainFalloff: Double? = nil,
        slowFactor: Double? = nil, slowDuration: Double? = nil, targets: Int? = nil,
        keepsDamageOnSlowed: Bool? = nil, vulnerableFactor: Double? = nil
    ) {
        self.cost = cost
        self.range = range
        self.damage = damage
        self.attackInterval = attackInterval
        self.targeting = targeting
        self.chainJumps = chainJumps
        self.chainRadius = chainRadius
        self.chainFalloff = chainFalloff
        self.slowFactor = slowFactor
        self.slowDuration = slowDuration
        self.targets = targets
        self.keepsDamageOnSlowed = keepsDamageOnSlowed
        self.vulnerableFactor = vulnerableFactor
    }
}

extension BalanceConfig {
    /// Ob ein Gegner der Mission Rüstung trägt (P2-10); Bots und Hinweise fragen hier.
    public var hasArmoredEnemies: Bool {
        EnemyKind.allCases.contains { (enemies[$0]?.armor ?? 0) > 0 }
    }
}

public struct EnemyConfig: Codable, Equatable, Sendable {
    public var hp: Double
    /// Felder je Sekunde
    public var speed: Double
    public var reward: Int
    public var leakDamage: Int
    /// Rüstung (K7, P2-10): fester Abzug je Turmtreffer. Fehlt sie, gibt es keine.
    public var armor: Double? = nil
    /// Anteil eines Treffers, den die Rüstung nie schluckt; nur zusammen mit `armor`.
    public var armorMinShare: Double? = nil

    public init(hp: Double, speed: Double, reward: Int, leakDamage: Int,
                armor: Double? = nil, armorMinShare: Double? = nil) {
        self.hp = hp
        self.speed = speed
        self.reward = reward
        self.leakDamage = leakDamage
        self.armor = armor
        self.armorMinShare = armorMinShare
    }
}

public struct WaveConfig: Codable, Equatable, Sendable {
    public var hpScale: Double
    public var groups: [SpawnGroup]

    public init(hpScale: Double, groups: [SpawnGroup]) {
        self.hpScale = hpScale
        self.groups = groups
    }
}

public struct SpawnGroup: Codable, Equatable, Sendable {
    public var enemy: EnemyKind
    public var count: Int
    /// Sekunden zwischen zwei Gegnern der Gruppe
    public var interval: Double
    /// Sekunden ab Wellenbeginn
    public var delay: Double?

    public init(enemy: EnemyKind, count: Int, interval: Double, delay: Double? = nil) {
        self.enemy = enemy
        self.count = count
        self.interval = interval
        self.delay = delay
    }
}
