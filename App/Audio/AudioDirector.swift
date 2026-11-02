import Foundation

/// Wohin Klänge und Musik gehen. `AudioEngine` spielt sie, Tests schreiben mit.
@MainActor
protocol SoundOutput: AnyObject {
    /// Länge einer geladenen Klangdatei in Sekunden, nil wenn sie fehlt.
    func duration(of file: String) -> Double?
    /// Startet einen Klang; false, wenn kein Spieler frei war.
    func play(file: String, gain: Float, rate: Float) -> Bool
    func setSoundVolume(_ volume: Float)
    func playMusic(file: String, loops: Bool, gain: Float, fade: TimeInterval)
    func setMusicGain(_ gain: Float, fade: TimeInterval)
    func stopMusic(fade: TimeInterval)
    /// App im Hintergrund oder Anruf: anhalten bzw. wieder anlaufen.
    func suspend()
    func resume()
}

/// Nimmt Momente aus der Szene und Lagen aus den Schirmen an und macht daraus
/// Klänge und Musik (docs/konzepte/p2-3-ton-und-musik.md). Wie der
/// `FxDirector` liest und ändert er keinen Spielzustand (Architekturregel 3).
@MainActor
final class AudioDirector {
    /// Was gespielt wurde. Für Tests und den E2E-Zähler `audio.stats`.
    struct Stats: Equatable {
        var played: [SoundCue: Int] = [:]
        var dropped = 0
        var mood: MusicMood?
        var moods = 0

        func count(_ cue: SoundCue) -> Int { played[cue] ?? 0 }

        var summary: String {
            let cues = SoundCue.allCases.map { "\($0.rawValue)=\(count($0))" }.joined(separator: " ")
            return "mood=\(mood?.rawValue ?? "none") moods=\(moods) \(cues) dropped=\(dropped)"
        }
    }

    static let shared = AudioDirector(output: AudioEngine())

    private let output: SoundOutput
    private let clock: () -> Double
    private var limiter = SoundLimiter()
    private var nextVariant: [SoundCue: Int] = [:]
    private var random: UInt64 = 0x9E37_79B9_7F4A_7C15
    private(set) var stats = Stats()
    private(set) var paused = false
    private(set) var soundVolume: Double
    private(set) var musicVolume: Double

    init(output: SoundOutput, defaults: UserDefaults = .standard,
         clock: @escaping () -> Double = { ProcessInfo.processInfo.systemUptime }) {
        self.output = output
        self.clock = clock
        soundVolume = AppSettings.soundVolume(in: defaults)
        musicVolume = AppSettings.musicVolume(in: defaults)
        output.setSoundVolume(Float(soundVolume))
    }

    // MARK: Klänge

    /// `interactive` = eigenes Spiel. Beim Zuschauen bleiben Bedientöne stumm.
    func play(_ moment: SoundMoment, interactive: Bool = true) {
        if SoundMap.isUserFeedback(moment) && !interactive { return }
        for request in SoundMap.requests(for: moment) { play(request) }
        if let mood = SoundMap.mood(after: moment) { setMood(mood) }
    }

    private func play(_ request: SoundMap.Request) {
        let cue = request.cue
        let mix = AudioStyle.mix(cue)
        let file = variant(of: cue)
        let semitones = request.semitones + spread(mix.spread)
        let rate = pow(2, semitones / 12)
        let length = (output.duration(of: file) ?? 0) / Double(rate)
        guard limiter.admit(cue, at: clock(), duration: length) else { stats.dropped += 1; return }
        guard output.play(file: file, gain: mix.gain, rate: rate) else { stats.dropped += 1; return }
        stats.played[cue, default: 0] += 1
    }

    /// Fassungen der Reihe nach, damit derselbe Klang nie zweimal hintereinander kommt.
    private func variant(of cue: SoundCue) -> String {
        let files = cue.files
        let index = nextVariant[cue, default: 0] % files.count
        nextVariant[cue] = index + 1
        return files[index]
    }

    /// Gleichverteilt in ±`range` Halbtönen. Eigener Generator (Darstellung,
    /// nicht Simulation), gesät, damit Tests wiederholbar sind.
    private func spread(_ range: Float) -> Float {
        guard range > 0 else { return 0 }
        random = random &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        let unit = Float(random >> 40) / Float(1 << 24)
        return (unit * 2 - 1) * range
    }

    // MARK: Musik

    func setMood(_ mood: MusicMood) {
        guard stats.mood != mood else { return }
        stats.mood = mood
        stats.moods += 1
        output.playMusic(file: mood.file, loops: mood.loops, gain: musicGain, fade: AudioStyle.crossfade)
    }

    /// Ein neuer Kampf beginnt (auch nach „Neustart"): Begrenzer leeren, Kampfmusik.
    func startBattle() {
        limiter.reset()
        setPaused(false)
        setMood(.battle)
    }

    func setPaused(_ on: Bool) {
        guard paused != on else { return }
        paused = on
        output.setMusicGain(musicGain, fade: AudioStyle.fadeOut)
    }

    var musicGain: Float { AudioStyle.musicGain * Float(musicVolume) * (paused ? AudioStyle.pauseDuck : 1) }

    // MARK: Einstellungen und Lebenslauf

    func setSoundVolume(_ value: Double) {
        soundVolume = min(max(value, 0), 1)
        output.setSoundVolume(Float(soundVolume))
    }

    func setMusicVolume(_ value: Double) {
        musicVolume = min(max(value, 0), 1)
        output.setMusicGain(musicGain, fade: 0)
    }

    /// Probeton beim Loslassen des Klangreglers: Man hört, was man eingestellt hat.
    func preview() { play(.user(.selectCell)) }

    func suspend() { output.suspend() }
    func resume() { output.resume() }
}
