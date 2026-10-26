import OddlingsCore
import UIKit

/// Haptik-Arten aus 07-ui-ux.md, Abschnitt 5.
enum Haptic: Equatable, Sendable {
    case selection, light, medium, heavy, warning, success, error
}

/// Handlungen, die schon vor der Simulation eine Rückmeldung brauchen: Sie
/// bauen oder kosten noch nichts, der Finger soll trotzdem spüren, dass der
/// Tipp ankam.
enum UserAction: Equatable, Sendable {
    case selectCell, preview, armSell, callWave, cannotAfford
}

/// Was der Spieler spürt. Die Zuordnung ist rein und getestet
/// (`FeedbackPlayerTests`); nur `play` fasst UIKit an. Ton kommt mit K9 hinzu.
@MainActor
enum FeedbackPlayer {
    static func haptic(for action: UserAction) -> Haptic {
        switch action {
        case .selectCell, .preview, .armSell: .selection
        case .callWave: .heavy
        case .cannotAfford: .warning
        }
    }

    /// Ereignisse aus der Simulation. Treffer, Tode und Wellenstarts bleiben
    /// still: In einer vollen Welle wären das Dutzende je Sekunde, und dann
    /// spürt man die eigene Handlung nicht mehr.
    static func haptic(for event: Event) -> Haptic? {
        switch event {
        case .towerBuilt: .medium
        case .towerSold: .light
        case .commandRejected: .warning
        case .enemyLeaked: .warning
        case .missionEnded(let won): won ? .success : .error
        case .abilityCast: .light
        case .abilityImpact: .heavy
        case .barrierRaised: .heavy
        case .barrierFell: nil
        case .towerFired, .enemyDamaged, .enemySlowed, .enemyKilled, .waveStarted, .enemySpawned: nil
        }
    }

    static func play(_ haptic: Haptic) {
        guard AppSettings.vibration() else { return }
        switch haptic {
        case .selection: UISelectionFeedbackGenerator().selectionChanged()
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy: UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
