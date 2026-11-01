import OddlingsCore

/// Was im Spiel zu hören ist, unabhängig davon, welche Datei es trägt
/// (docs/konzepte/p2-3-ton-und-musik.md). Die Szene übersetzt Ereignisse in
/// Momente; `SoundMap` wählt den Klang.
enum SoundMoment: Equatable, Sendable {
    case built, sold, rejected
    /// `links` = Ziele in der Kette (Blitz), `combo` = ein Ziel war verlangsamt (E2).
    case fired(TowerKind, links: Int, combo: Bool)
    case damaged, slowed, killed, leaked
    case waveStarted(index: Int, count: Int)
    case missionEnded(won: Bool)
    case abilityCast
    case abilityImpact(moon: Bool)
    case wallRaised, wallFell
    /// Zwergenbank zahlt aus bzw. frühes Rufen schreibt Gold gut (P2-5).
    case bankPaid, earlyCallBonus
    case user(UserAction)
}

/// Ein Klang mit seinen Fassungen. Der Name ist zugleich Dateistamm:
/// `watchShot` → `watch_shot_1.caf`, `watch_shot_2.caf` …
enum SoundCue: String, CaseIterable, Sendable {
    case uiTap, uiConfirm, uiDeny
    case build, sell
    case watchShot, boltShot, sporePuff, combo
    case hit, slowed, enemyPop, coin, leak
    case wave, abilityCast, stoneImpact, moonImpact, wallUp, wallDown

    /// `uiTap` → `ui_tap`.
    var stem: String {
        rawValue.reduce(into: "") { name, char in
            if char.isUppercase { name += "_" + char.lowercased() } else { name.append(char) }
        }
    }

    var files: [String] { (1...AudioStyle.mix(self).variants).map { "\(stem)_\($0).caf" } }
}

/// Musik nach Lage (Marktanalyse Abschnitt 3: „Musik wechselt mit der Lage").
enum MusicMood: String, CaseIterable, Sendable {
    case menu, battle, finalWave, victory, defeat

    var file: String {
        switch self {
        case .menu: "music_menu.m4a"
        case .battle: "music_battle.m4a"
        case .finalWave: "music_final_wave.m4a"
        case .victory: "music_victory.m4a"
        case .defeat: "music_defeat.m4a"
        }
    }

    /// Sieg und Niederlage klingen einmal aus, alles andere schleift.
    var loops: Bool { self != .victory && self != .defeat }
}
