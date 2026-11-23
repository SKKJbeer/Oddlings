import OddlingsCore
import SpriteKit

/// Was am Turmbild lebt (A-5 Teil 3, G9, D-185 bis D-188): wo die Schützen auf
/// der Plattform stehen und wo der Hut eines Sporenbilds ansetzt. Der Wert ist
/// Darstellung und hängt am gemalten Bild, darum liegt er bei der App in
/// `turmkronen.json`; tools/art-check prüft ihn gegen den Atlas.
@MainActor
enum TowerCrownTable {
    struct Entry: Equatable {
        /// Fußpunkte der Schützen als Anteil des Turmbilds (x von links, y von unten).
        var shooters: [CGPoint] = []
        /// Unterkante des Huts als Anteil der Bildhöhe von unten; nil = kein Hut.
        var capLine: CGFloat?
    }

    static let table: [String: Entry] = {
        guard let url = Bundle.main.url(forResource: "turmkronen", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return parse(data)
    }()

    static func entry(for picture: String) -> Entry { table[picture] ?? Entry() }

    /// Nur Einträge `tower_…`; Punkte müssen im Bild liegen (0…1). Fehlerhafte
    /// Einträge fallen einzeln weg, statt die ganze Tabelle zu verwerfen.
    static func parse(_ data: Data) -> [String: Entry] {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        var result: [String: Entry] = [:]
        for (key, value) in object where key.hasPrefix("tower_") {
            guard let fields = value as? [String: Any] else { continue }
            var entry = Entry()
            if let points = fields["schuetzen"] as? [[Double]] {
                entry.shooters = points.compactMap { p in
                    guard p.count == 2, p.allSatisfy({ (0...1).contains($0) }) else { return nil }
                    return CGPoint(x: p[0], y: p[1])
                }
            }
            if let line = fields["hutLinie"] as? Double, (0...1).contains(line) { entry.capLine = CGFloat(line) }
            result[key] = entry
        }
        return result
    }
}

/// Blickrichtung des Schützen: acht Bilder, 0 = rechts, gegen den Uhrzeigersinn
/// in 45°, wie die Sonne im Asset-Vertrag (D-185). Die Szene ist in der Tiefe
/// schon so gestreckt, dass eine Bodenzelle quadratisch ist; der Winkel in der
/// Szene ist also der Winkel auf dem Boden. Rein und ohne SpriteKit-Zustand,
/// damit die Tests Drehtempo und Hysterese ohne Szene prüfen.
struct GuardFacing: Equatable {
    static let sectors = 8
    static let sectorWidth = 2 * Double.pi / Double(sectors)

    /// Winkel, in den die Figur gerade blickt (Bogenmaß, 0 = rechts).
    private(set) var angle: Double
    /// Gezeigtes Bild 0…7; wechselt erst jenseits der Hysterese.
    private(set) var sector: Int

    init(angle: Double = -Double.pi / 2) {
        self.angle = GuardFacing.normalized(angle)
        sector = GuardFacing.nearestSector(self.angle)
    }

    /// Dreht höchstens `rate` Bogenmaß je Sekunde zum Ziel; `snap` springt (weniger Bewegung).
    mutating func turn(toward goal: Double, dt: Double, rate: Double, hysteresis: Double, snap: Bool) {
        let delta = GuardFacing.difference(goal, angle)
        if snap || abs(delta) <= rate * dt {
            angle = GuardFacing.normalized(goal)
        } else {
            angle = GuardFacing.normalized(angle + (delta > 0 ? 1 : -1) * rate * dt)
        }
        let candidate = GuardFacing.nearestSector(angle)
        guard candidate != sector else { return }
        // Erst wechseln, wenn der Winkel deutlich im neuen Sektor liegt, sonst
        // flackert die Figur an der Grenze zweier Bilder.
        let fromCurrent = abs(GuardFacing.difference(angle, GuardFacing.center(of: sector)))
        if snap || fromCurrent > GuardFacing.sectorWidth / 2 + hysteresis { sector = candidate }
    }

    /// Ob das gezeigte Bild in die Richtung `goal` blickt: im eigenen Sektor,
    /// erweitert um die Hysterese, in der es absichtlich noch nicht wechselt.
    func faces(_ goal: Double, hysteresis: Double) -> Bool {
        abs(GuardFacing.difference(goal, GuardFacing.center(of: sector))) <= GuardFacing.sectorWidth / 2 + hysteresis
    }

    static func center(of sector: Int) -> Double { Double(sector) * sectorWidth }

    static func nearestSector(_ angle: Double) -> Int {
        Int((normalized(angle) / sectorWidth).rounded()) % sectors
    }

    static func normalized(_ angle: Double) -> Double {
        let full = 2 * Double.pi
        let r = angle.truncatingRemainder(dividingBy: full)
        return r < 0 ? r + full : r
    }

    /// Kürzester Weg von `b` nach `a`, −π…π.
    static func difference(_ a: Double, _ b: Double) -> Double {
        var d = normalized(a) - normalized(b)
        if d > Double.pi { d -= 2 * Double.pi }
        if d < -Double.pi { d += 2 * Double.pi }
        return d
    }
}

/// Wer auf dem Wachturm steht (D-185): Der Schütze folgt dem Volk des Avatars,
/// Zwerg mit Armbrust oder Elf mit Bogen. Beide haben dieselbe Bewegung und
/// denselben Vertrag, nur andere Bilder.
enum GuardFigure: String, CaseIterable, Sendable {
    case dwarf = "tower_guard"
    case elf = "tower_guardElf"

    init(race: Race?) { self = race == .elves ? .elf : .dwarf }

    /// Fehlen die Bilder eines Volks, steht der Zwerg da statt eines leeren Turms.
    @MainActor var available: GuardFigure? {
        if ShooterNode.complete(self) { return self }
        return self != .dwarf && ShooterNode.complete(.dwarf) ? .dwarf : nil
    }
}

/// Der Schütze auf dem Wachturm (D-185): eigene 3D-Figur, acht Richtungen, je
/// eine Schussfolge `<figur>_shoot<r>_NN`. Bild 00 ist der Anschlag, in dem
/// er wartet und zielt; 01 bis zum Ende Abdrücken, Rückstoß, Spannen.
@MainActor
final class ShooterNode: SKSpriteNode {
    static let shootName = "tower_guard_shoot"

    static func frameName(_ figure: GuardFigure = .dwarf, sector: Int, frame: Int) -> String {
        "\(figure.rawValue)_shoot\(sector)_" + String(format: "%02d", frame)
    }

    let figure: GuardFigure

    private(set) var facing = GuardFacing()
    /// Ziel im Moment, für Tests und die Messung „Schütze blickt aufs Ziel“.
    private(set) var goal: Double?
    /// Index im Schuss (nil = im Anschlag); gesetzt vom FxDirector.
    var shotFrame: Int? { didSet { if shotFrame != oldValue { showFrame() } } }

    /// Irgendein Schütze da? Fehlen alle Bilder, bleibt der Turm leer (Rückfall).
    static var available: Bool { GuardFigure.dwarf.available != nil }

    /// Alle acht Richtungen einer Figur da?
    static func complete(_ figure: GuardFigure) -> Bool {
        (0..<GuardFacing.sectors).allSatisfy { BattleSprites.texture(named: frameName(figure, sector: $0, frame: 0)) != nil }
    }

    init(field: CGFloat, figure: GuardFigure = .dwarf) {
        self.figure = figure
        let side = BattleStyle.guardSpriteSide * field
        super.init(texture: BattleSprites.texture(named: Self.frameName(figure, sector: GuardFacing().sector, frame: 0)),
                   color: .white, size: CGSize(width: side, height: side))
        anchorPoint = CGPoint(x: 0.5, y: BattleStyle.guardAnchorY)
        name = Self.shootName
        showFrame()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("nicht benutzt") }

    /// Richtung zum Ziel (Szenenwinkel) oder nil ohne Ziel: Dann bleibt er stehen.
    func aim(at angle: Double?, dt: Double, still: Bool) {
        goal = angle
        guard let angle else { return }
        let before = facing.sector
        facing.turn(toward: angle, dt: dt, rate: FxStyle.guardTurnRate, hysteresis: FxStyle.guardHysteresis,
                    snap: still)
        if facing.sector != before { showFrame() }
    }

    /// Übernimmt die Blickrichtung eines Vorgängers (neues Turmbild nach dem Aufwerten).
    func restore(_ previous: GuardFacing) {
        facing = previous
        showFrame()
    }

    /// Blickt das gezeigte Bild zum Ziel? Ohne Ziel: ja, er wartet.
    var onTarget: Bool { goal.map { facing.faces($0, hysteresis: FxStyle.guardHysteresis) } ?? true }

    /// Mündung der Armbrust in Turmkoordinaten, für den Start des Pfeils.
    var muzzle: CGPoint {
        let a = GuardFacing.center(of: facing.sector)
        let reach = BattleStyle.guardMuzzleReach * size.width
        return CGPoint(x: position.x + CGFloat(cos(a)) * reach,
                       y: position.y + CGFloat(sin(a)) * reach + BattleStyle.guardMuzzleHeight * size.height)
    }

    private(set) var shownName = ""

    private func showFrame() {
        let name = Self.frameName(figure, sector: facing.sector, frame: shotFrame ?? 0)
        guard name != shownName, let texture = BattleSprites.texture(named: name) else { return }
        self.texture = texture
        shownName = name
    }

    /// Bilder der Schussfolge nach dem Anschlag (ohne Bild 00), je Figur einmal gezählt.
    var shotLength: Int { Self.shotLengths[figure] ?? 0 }

    private static let shotLengths: [GuardFigure: Int] = Dictionary(uniqueKeysWithValues: GuardFigure.allCases.map { figure in
        var count = 1
        while count < 20, BattleSprites.texture(named: frameName(figure, sector: 0, frame: count)) != nil { count += 1 }
        return (figure, count - 1)
    })
}

/// Verzerrungsgitter, das den Hut eines Sporenturms anhebt (D-188): unter dem
/// Band bleibt das Bild, im Band dehnt sich der Stiel, darüber verschiebt sich
/// alles um `lift` (Anteil der Bildhöhe).
enum CapWarp {
    static func grid(capLine: CGFloat, band: CGFloat, lift: CGFloat) -> SKWarpGeometryGrid {
        let low = Float(max(0, capLine - band)), line = Float(capLine), up = Float(lift)
        let source: [SIMD2<Float>] = [[0, 0], [1, 0], [0, low], [1, low], [0, line], [1, line], [0, 1], [1, 1]]
        let destination: [SIMD2<Float>] = [[0, 0], [1, 0], [0, low], [1, low],
                                           [0, line + up], [1, line + up], [0, 1 + up], [1, 1 + up]]
        return SKWarpGeometryGrid(columns: 1, rows: 3, sourcePositions: source, destinationPositions: destination)
    }
}
