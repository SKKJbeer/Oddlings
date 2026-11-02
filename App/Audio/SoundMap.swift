import OddlingsCore

/// Welcher Klang zu welchem Moment gehört, und welche Musik zu welcher Lage.
/// Rein und getestet (`SoundMapTests`): Die Tabelle aus dem Konzept steht hier
/// genau einmal.
enum SoundMap {
    /// Ein Klang mit Tonhöhenverschiebung in Halbtönen (vor der Streuung).
    struct Request: Equatable, Sendable {
        var cue: SoundCue
        var semitones: Float = 0
    }

    static func requests(for moment: SoundMoment) -> [Request] {
        switch moment {
        case .built: [Request(cue: .build)]
        case .sold: [Request(cue: .sell)]
        case .rejected: [Request(cue: .uiDeny)]
        case .fired(.watch, _, _): [Request(cue: .watchShot)]
        case .fired(.lightning, let links, let combo):
            [Request(cue: .boltShot, semitones: boltPitch(links: links))] + (combo ? [Request(cue: .combo)] : [])
        case .fired(.spore, _, _): [Request(cue: .sporePuff)]
        // Die Bank schießt nicht; sie meldet sich nur beim Auszahlen.
        case .fired(.bank, _, _): []
        case .damaged: [Request(cue: .hit)]
        case .slowed: [Request(cue: .slowed)]
        case .killed: [Request(cue: .enemyPop), Request(cue: .coin)]
        case .leaked: [Request(cue: .leak)]
        case .waveStarted: [Request(cue: .wave)]
        // Das Ende spricht die Musik (Fanfare oder Ausklang), kein eigener Klang.
        case .missionEnded: []
        case .abilityCast: [Request(cue: .abilityCast)]
        case .abilityImpact(let moon): [Request(cue: moon ? .moonImpact : .stoneImpact)]
        case .wallRaised: [Request(cue: .wallUp)]
        case .wallFell: [Request(cue: .wallDown)]
        // Leise Münze statt eigenem Klang: Gold kommt herein, wie beim Sturz.
        case .bankPaid, .earlyCallBonus: [Request(cue: .coin)]
        case .user(let action): [Request(cue: cue(for: action))]
        }
    }

    static func cue(for action: UserAction) -> SoundCue {
        switch action {
        case .selectCell, .preview, .armSell: .uiTap
        case .callWave: .uiConfirm
        case .cannotAfford: .uiDeny
        }
    }

    /// „Knistern, je Sprung höher": eine Stufe je weiteres Glied, gedeckelt.
    static func boltPitch(links: Int) -> Float {
        Float(min(max(links - 1, 0), AudioStyle.boltMaxSteps)) * AudioStyle.boltStepSemitones
    }

    /// Lage nach einem Moment im Kampf, nil = Lage bleibt.
    static func mood(after moment: SoundMoment) -> MusicMood? {
        switch moment {
        case .waveStarted(let index, let count): index == count - 1 ? .finalWave : nil
        case .missionEnded(let won): won ? .victory : .defeat
        default: nil
        }
    }

    /// Bedientöne nur im eigenen Spiel; die Vorführung bedient niemand.
    static func isUserFeedback(_ moment: SoundMoment) -> Bool {
        if case .user = moment { return true }
        return false
    }
}
