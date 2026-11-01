/// Hält die Dichte gleicher Klänge in Grenzen („Höchstens vier gleichzeitige
/// Klänge derselben Art; weitere entfallen", Rückmeldeliste). Rein: Die Uhr
/// kommt von außen, damit Tests ohne Warten laufen.
struct SoundLimiter {
    private var playing: [SoundCue: [Double]] = [:]
    private var lastStart: [SoundCue: Double] = [:]

    /// Darf `cue` jetzt starten? Bei Ja ist die Stimme bis `now + duration` belegt.
    mutating func admit(_ cue: SoundCue, at now: Double, duration: Double) -> Bool {
        let mix = AudioStyle.mix(cue)
        if let last = lastStart[cue], now - last < mix.spacing { return false }
        var ends = (playing[cue] ?? []).filter { $0 > now }
        guard ends.count < mix.voices else { playing[cue] = ends; return false }
        ends.append(now + duration)
        playing[cue] = ends
        lastStart[cue] = now
        return true
    }

    mutating func reset() {
        playing = [:]
        lastStart = [:]
    }
}
