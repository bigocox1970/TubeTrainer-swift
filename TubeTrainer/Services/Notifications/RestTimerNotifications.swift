import Foundation
import UserNotifications

/// Handles the single legitimate notification use: a rest timer finishing while
/// TubeTrainer is backgrounded. Permission is requested *in context* (when the
/// user first starts a rest timer), never at launch/onboarding.
@MainActor
final class RestTimerNotifications {
    static let shared = RestTimerNotifications()
    private let center = UNUserNotificationCenter.current()
    private let restID = "tt.rest.finished"

    private init() {}

    /// Request permission the first time it's actually needed. Returns whether granted.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    func currentStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Schedule the completion alert. Cancels any prior one first.
    func scheduleRestFinished(after seconds: TimeInterval, playSound: Bool) {
        cancel()
        guard seconds > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Rest complete"
        content.body = "Time for your next set."
        content.sound = playSound ? .default : nil
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: restID, content: content, trigger: trigger)
        center.add(request)
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [restID])
        center.removeDeliveredNotifications(withIdentifiers: [restID])
    }
}
