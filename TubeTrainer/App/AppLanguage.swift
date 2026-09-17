import Foundation

/// In-app language override on top of the system language.
///
/// The app defaults to the device language. When the user picks a specific
/// language in Settings, we redirect `Bundle.main`'s localized-string lookups to
/// that language's `.lproj`, so all `Text`/`String(localized:)`/`TTLocalized`
/// resolve to it — without needing a relaunch (the root view is re-keyed so the
/// whole tree re-renders). Passing "" restores the system language.

private var ttBundleKey: UInt8 = 0

/// `Bundle.main` gets reclassed to this so its lookups can be redirected.
final class TTLanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let override = objc_getAssociatedObject(self, &ttBundleKey) as? Bundle {
            return override.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

enum AppLanguage {
    /// Codes offered in Settings. "" == follow the system language.
    static let options: [(code: String, name: String)] = [
        ("", "System"),          // localized ("System"/"Sistema"/...)
        ("en", "English"),       // endonyms below stay verbatim
        ("es", "Español"),
        ("pt-BR", "Português"),
        ("de", "Deutsch"),
    ]

    /// Apply a language override. nil / "" follows the system language.
    static func apply(_ code: String?) {
        if !(Bundle.main is TTLanguageBundle) {
            object_setClass(Bundle.main, TTLanguageBundle.self)
        }
        let override: Bundle?
        if let code, !code.isEmpty, let path = Bundle.main.path(forResource: code, ofType: "lproj") {
            override = Bundle(path: path)
        } else {
            override = nil
        }
        objc_setAssociatedObject(Bundle.main, &ttBundleKey, override, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // Keep AppleLanguages in sync for system-driven lookups + next launch.
        if let code, !code.isEmpty {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    /// Locale that drives SwiftUI number/date formatting + plural selection.
    static func locale(for code: String) -> Locale {
        code.isEmpty ? Locale.autoupdatingCurrent : Locale(identifier: code)
    }
}
