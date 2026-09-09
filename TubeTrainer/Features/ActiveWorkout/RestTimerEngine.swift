import SwiftUI
import Observation

/// Drives the rest timer. Background-correct: remaining time is derived from an
/// absolute `endDate`, so it stays accurate across backgrounding/relaunch. A local
/// notification fires if the app is backgrounded when it completes.
@Observable
@MainActor
final class RestTimerEngine {
    private(set) var endDate: Date?
    private(set) var totalSeconds: Int = 0
    private(set) var isRunning = false

    /// Recomputed each tick so the UI updates smoothly.
    private(set) var remaining: Int = 0

    private var ticker: Timer?
    var onComplete: (() -> Void)?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - (Double(remaining) / Double(totalSeconds))
    }

    func start(seconds: Int, playSound: Bool) {
        guard seconds > 0 else { return }
        totalSeconds = seconds
        endDate = Date().addingTimeInterval(TimeInterval(seconds))
        remaining = seconds
        isRunning = true
        scheduleTicker()

        Task {
            let granted = await RestTimerNotifications.shared.requestAuthorizationIfNeeded()
            if granted, isRunning {
                RestTimerNotifications.shared.scheduleRestFinished(after: TimeInterval(seconds), playSound: playSound)
            }
        }
    }

    func add(seconds: Int) {
        guard isRunning, let end = endDate else { return }
        endDate = end.addingTimeInterval(TimeInterval(seconds))
        totalSeconds += seconds
        recompute()
        rescheduleNotification()
    }

    func skip() {
        stop(fireCompletion: false)
    }

    /// Recompute remaining from wall clock — call on foreground return.
    func refresh() {
        guard isRunning else { return }
        recompute()
    }

    private func stop(fireCompletion: Bool) {
        ticker?.invalidate()
        ticker = nil
        isRunning = false
        endDate = nil
        remaining = 0
        RestTimerNotifications.shared.cancel()
        if fireCompletion { onComplete?() }
    }

    private func scheduleTicker() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.recompute() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func recompute() {
        guard let end = endDate else { return }
        let left = Int(ceil(end.timeIntervalSinceNow))
        if left <= 0 {
            remaining = 0
            TTHaptics.restFinished()
            stop(fireCompletion: true)
        } else {
            remaining = left
        }
    }

    private func rescheduleNotification() {
        guard isRunning, remaining > 0 else { return }
        Task {
            let granted = await RestTimerNotifications.shared.currentStatus()
            if granted == .authorized || granted == .provisional {
                RestTimerNotifications.shared.scheduleRestFinished(
                    after: TimeInterval(remaining),
                    playSound: AppSettings.shared.restAlertSound
                )
            }
        }
    }
}
