import Foundation

/// Reine Rechnungen der Effekte: Kurven, Laufhaltung, Blitzzacken, Flugbahnen,
/// Wackeln. Nur Foundation, damit `AppTests` sie ohne Szene und ohne
/// Bildschirm prüfen können (docs/konzepte/fx-01-bewegung-und-effekte.md).
struct Vec: Equatable {
    var x: Double
    var y: Double

    static let zero = Vec(x: 0, y: 0)
    static func + (a: Vec, b: Vec) -> Vec { Vec(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: Vec, b: Vec) -> Vec { Vec(x: a.x - b.x, y: a.y - b.y) }
    static func * (a: Vec, k: Double) -> Vec { Vec(x: a.x * k, y: a.y * k) }
    var length: Double { (x * x + y * y).squareRoot() }
    var angle: Double { atan2(y, x) }
}

/// Zeitverläufe von 0 bis 1. Lineare Bewegung wirkt mechanisch; fast jede
/// Bewegung im Spiel startet oder landet mit einer Kurve.
enum Ease {
    // Überschwingen nach Robert Penner, der übliche Wert für „federt leicht nach".
    private static let c1 = 1.70158
    private static let c3 = c1 + 1

    private static func clamp(_ t: Double) -> Double { min(1, max(0, t)) }

    static func linear(_ t: Double) -> Double { clamp(t) }
    static func quadIn(_ t: Double) -> Double { let t = clamp(t); return t * t }
    static func quadOut(_ t: Double) -> Double { let t = clamp(t); return 1 - (1 - t) * (1 - t) }
    static func cubicOut(_ t: Double) -> Double { 1 - pow(1 - clamp(t), 3) }
    static func sineInOut(_ t: Double) -> Double { -(cos(Double.pi * clamp(t)) - 1) / 2 }
    static func backIn(_ t: Double) -> Double { let t = clamp(t); return c3 * t * t * t - c1 * t * t }
    static func backOut(_ t: Double) -> Double { let t = clamp(t); return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2) }
    static func elasticOut(_ t: Double) -> Double {
        let t = clamp(t)
        if t == 0 || t == 1 { return t }
        return pow(2, -10 * t) * sin((t * 10 - 0.75) * (2 * Double.pi / 3)) + 1
    }
}

/// Wie eine Gegnerart läuft. Längen in Feldern, Winkel im Bogenmaß.
struct Gait: Equatable {
    /// Strecke je Schritt. Ein Schritt ist ein Hüpfer.
    var stride: Double
    /// Höchster Punkt des Hüpfers.
    var hop: Double
    /// Stauchen beim Aufsetzen (0,2 = 20 % flacher).
    var squash: Double
    /// Wiegen von einer Seite zur anderen, je zwei Schritte hin und zurück.
    var sway: Double
    /// Vorneigung in Laufrichtung.
    var lean: Double
}

/// Haltung eines laufenden Gegners in einem Augenblick.
struct Pose: Equatable {
    /// Anheben des Körpers über den Boden, in Feldern.
    var lift: Double
    var scaleX: Double
    var scaleY: Double
    /// Drehung für Blick nach rechts; nach links spiegelt die Szene.
    var tilt: Double
    /// Größe des Schattens, 1 am Boden.
    var shadow: Double

    static let rest = Pose(lift: 0, scaleX: 1, scaleY: 1, tilt: 0, shadow: 1)
}

enum FxMath {
    /// Laufhaltung aus der zurückgelegten Strecke, nicht aus der Uhr: So rutschen
    /// die Füße nie, und ein verlangsamter Gegner trippelt von selbst langsamer.
    /// `phase` (0 bis 1) verschiebt den Takt, damit eine Welle nicht im
    /// Gleichschritt hüpft.
    static func pose(distance: Double, phase: Double, gait: Gait) -> Pose {
        guard gait.stride > 0 else { return .rest }
        let steps = distance / gait.stride + phase
        let within = steps - floor(steps)
        // 0 beim Aufsetzen, 1 im höchsten Punkt.
        let air = sin(Double.pi * within)
        let contact = 1 - air
        // Hoch potenziert: Das Stauchen sitzt kurz und hart im Aufsetzen, wie
        // bei einem Ball, statt den ganzen Schritt weich zu wabern.
        let squash = gait.squash * pow(contact, 4)
        let stretch = gait.squash * 0.4 * air
        return Pose(
            lift: gait.hop * air,
            scaleX: 1 + squash * 0.8 - stretch * 0.5,
            scaleY: 1 - squash + stretch,
            tilt: gait.sway * sin(Double.pi * steps) - gait.lean,
            shadow: 1 - 0.3 * air
        )
    }

    /// Bild einer Laufbildfolge (FX 02) aus der zurückgelegten Strecke wie bei
    /// `pose`: Die Füße setzen dort auf, wo der Gegner gerade ist, egal wie
    /// schnell die Bilder kommen oder ob er verlangsamt ist. Eine Folge zeigt
    /// zwei Schritte, ein Bein nach dem anderen.
    static func walkFrame(distance: Double, phase: Double, stride: Double, frames: Int) -> Int {
        guard stride > 0, frames > 0 else { return 0 }
        let cycles = distance / (2 * stride) + phase
        return min(frames - 1, Int((cycles - floor(cycles)) * Double(frames)))
    }

    /// Bild einer einmaligen Folge (Treffer, Sturz) beim Anteil `t` von 0 bis 1;
    /// das letzte Bild bleibt stehen.
    static func onceFrame(_ t: Double, frames: Int) -> Int {
        guard frames > 0 else { return 0 }
        return min(frames - 1, max(0, Int(t * Double(frames))))
    }

    /// Takt eines Gegners aus seiner Kennung, 0 bis 1. Goldener Schnitt, damit
    /// aufeinanderfolgende Kennungen weit auseinander liegen.
    static func phase(forID id: Int) -> Double {
        let value = Double(id) * 0.618_033_988_75
        return value - floor(value)
    }

    /// Punkte eines gezackten Blitzes von `a` nach `b`. Anfang und Ende liegen
    /// genau auf den Zielen; die Ausschläge sind in der Mitte am größten.
    static func boltPoints<R: RandomNumberGenerator>(from a: Vec, to b: Vec, segments: Int,
                                                     jitter: Double, using random: inout R) -> [Vec] {
        let count = max(1, segments)
        let delta = b - a
        let length = delta.length
        guard length > 0 else { return [a, b] }
        let normal = Vec(x: -delta.y / length, y: delta.x / length)
        var points = [a]
        for index in 1..<count {
            let t = Double(index) / Double(count)
            let offset = Double.random(in: -1...1, using: &random) * jitter * length * sin(Double.pi * t)
            points.append(a + delta * t + normal * offset)
        }
        points.append(b)
        return points
    }

    /// Ort auf einer Wurfbahn von `a` nach `b` mit Scheitelhöhe `height` über
    /// der Verbindungslinie, dazu die Flugrichtung (für die Pfeilspitze).
    static func arc(from a: Vec, to b: Vec, height: Double, at t: Double) -> (point: Vec, angle: Double) {
        let point = a + (b - a) * t + Vec(x: 0, y: height * 4 * t * (1 - t))
        let direction = (b - a) + Vec(x: 0, y: height * 4 * (1 - 2 * t))
        return (point, direction.angle)
    }

    /// Ort eines Teilchens mit Startgeschwindigkeit und Schwerkraft.
    static func ballistic(start: Vec, velocity: Vec, gravity: Double, at time: Double) -> Vec {
        start + velocity * time + Vec(x: 0, y: -0.5 * gravity * time * time)
    }

    /// Bildschirmwackeln: Stärke wächst mit dem Quadrat des „Traumas", damit
    /// kleine Anlässe kaum, große deutlich wackeln. Drei unrunde Frequenzen
    /// statt Zufall, damit es wiederholbar bleibt und nicht zittert.
    static func shake(trauma: Double, time: Double, amplitude: Double) -> Vec {
        let strength = amplitude * trauma * trauma
        let x = sin(time * 47.0) * 0.6 + sin(time * 83.0 + 1.3) * 0.4
        let y = sin(time * 53.0 + 0.7) * 0.6 + sin(time * 71.0 + 2.1) * 0.4
        return Vec(x: x * strength, y: y * strength)
    }

    /// Nachlaufendes Schadensstück im Lebensbalken: folgt nach unten verzögert,
    /// springt nach oben sofort (Heilung gibt es nicht, ein Neustart schon).
    static func lag(_ shown: Double, towards target: Double, dt: Double, rate: Double) -> Double {
        guard target < shown else { return target }
        return max(target, shown - max(rate * dt, (shown - target) * min(1, rate * 2 * dt)))
    }
}

/// Gesäter Zufall für die Darstellung. Die Simulation braucht ihn nicht (sie
/// hat ihren eigenen im Zustand); hier macht er Tests wiederholbar.
struct FxRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    /// SplitMix64: kurz, schnell und ohne Abhängigkeit.
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Bildzeiten einer Messperiode. Der Mittelwert sagt, ob es flüssig ist, das
/// längste Bild, ob es ruckelt.
struct FrameStats: Equatable {
    private(set) var frames = 0
    private(set) var total: Double = 0
    private(set) var worst: Double = 0

    mutating func add(_ frameTime: Double) {
        guard frameTime > 0 else { return }
        frames += 1
        total += frameTime
        worst = max(worst, frameTime)
    }

    var averageFPS: Double { total > 0 ? Double(frames) / total : 0 }
    var worstMS: Double { worst * 1000 }
}
