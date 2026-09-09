import SwiftUI
import Observation

/// Lightweight app-wide preferences persisted to UserDefaults.
/// Kept separate from SwiftData: these are device settings, not user content.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // Keys
    private enum Key {
        static let unit = "tt.weightUnit"
        static let defaultRest = "tt.defaultRestSeconds"
        static let autoStartRest = "tt.autoStartRest"
        static let appearance = "tt.appearance"
        static let onboarded = "tt.onboardingComplete"
        static let youtubeAPIKey = "tt.youtubeAPIKey"
        static let restAlertSound = "tt.restAlertSound"
    }

    var weightUnit: WeightUnit {
        didSet { defaults.set(weightUnit.rawValue, forKey: Key.unit) }
    }

    var defaultRestSeconds: Int {
        didSet { defaults.set(defaultRestSeconds, forKey: Key.defaultRest) }
    }

    var autoStartRest: Bool {
        didSet { defaults.set(autoStartRest, forKey: Key.autoStartRest) }
    }

    var appearance: AppearancePreference {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    var onboardingComplete: Bool {
        didSet { defaults.set(onboardingComplete, forKey: Key.onboarded) }
    }

    /// Optional user-supplied YouTube Data API key. Empty => search runs in
    /// compliant web fallback mode. Stored locally only; never transmitted anywhere
    /// but Google's API.
    var youtubeAPIKey: String {
        didSet { defaults.set(youtubeAPIKey, forKey: Key.youtubeAPIKey) }
    }

    var restAlertSound: Bool {
        didSet { defaults.set(restAlertSound, forKey: Key.restAlertSound) }
    }

    var hasYouTubeAPIKey: Bool {
        !youtubeAPIKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private init() {
        // Locale-based initial unit suggestion.
        let localeUsesMetric: Bool
        if #available(iOS 16, *) {
            localeUsesMetric = Locale.current.measurementSystem == .metric
        } else {
            localeUsesMetric = Locale.current.usesMetricSystem
        }

        if let raw = defaults.string(forKey: Key.unit), let u = WeightUnit(rawValue: raw) {
            weightUnit = u
        } else {
            weightUnit = localeUsesMetric ? .kg : .lb
        }

        defaultRestSeconds = defaults.object(forKey: Key.defaultRest) as? Int ?? 90
        autoStartRest = defaults.object(forKey: Key.autoStartRest) as? Bool ?? true
        restAlertSound = defaults.object(forKey: Key.restAlertSound) as? Bool ?? true

        if let raw = defaults.string(forKey: Key.appearance), let a = AppearancePreference(rawValue: raw) {
            appearance = a
        } else {
            appearance = .dark   // dark-first identity
        }

        onboardingComplete = defaults.bool(forKey: Key.onboarded)
        youtubeAPIKey = defaults.string(forKey: Key.youtubeAPIKey) ?? ""
    }

    /// Common rest presets in seconds.
    static let restPresets: [Int] = [60, 90, 120, 180]
}
