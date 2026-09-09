import UIKit

/// Intentional haptics. Used for meaningful moments only — never on every tap.
enum TTHaptics {
    static func setCompleted() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func restFinished() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func workoutCompleted() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func coachSelected() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func reorderSnap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func lightTick() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
