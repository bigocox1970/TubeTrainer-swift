import SwiftUI

// MARK: - UpdateChecker
//
// Reusable "a newer version is on the App Store" notifier. Backend-free: it queries
// Apple's public iTunes lookup API by bundle id, so there's nothing to host and no
// per-app configuration. Reads the running version + bundle id from `Bundle.main`,
// and takes the store URL straight from the lookup response.
//
// Drop this single file into any iOS app and add `.checkForAppUpdate()` to the root
// view. Nothing here is TubeTrainer-specific.

@MainActor
@Observable
final class UpdateChecker {
    /// The newest version string reported by the App Store, if known.
    private(set) var latestVersion: String?
    /// Where to send the user to update.
    private(set) var storeURL: URL?
    /// True when the App Store version is strictly newer than the running build.
    private(set) var updateAvailable = false

    private let bundleID: String
    private let currentVersion: String
    private let country: String?
    private let minCheckInterval: TimeInterval
    private let session: URLSession
    private let defaults: UserDefaults
    private let now: () -> Date

    private static let lastCheckKey = "UpdateChecker.lastCheckAt"
    private static let cachedVersionKey = "UpdateChecker.cachedLatestVersion"
    private static let cachedURLKey = "UpdateChecker.cachedStoreURL"

    init(bundleID: String = Bundle.main.bundleIdentifier ?? "",
         currentVersion: String = Bundle.main.appShortVersion,
         country: String? = Locale.current.region?.identifier,
         minCheckInterval: TimeInterval = 60 * 60 * 12,
         session: URLSession = .shared,
         defaults: UserDefaults = .standard,
         now: @escaping () -> Date = Date.init) {
        self.bundleID = bundleID
        self.currentVersion = currentVersion
        self.country = country
        self.minCheckInterval = minCheckInterval
        self.session = session
        self.defaults = defaults
        self.now = now
    }

    /// Check for a newer App Store version. Network calls are throttled to
    /// `minCheckInterval`; between calls the last known result is reused so the
    /// prompt still appears on every launch when the user is behind.
    func check(force: Bool = false) async {
        guard !bundleID.isEmpty else { return }

        // Reuse the cached result if we checked recently (unless forced).
        let last = defaults.object(forKey: Self.lastCheckKey) as? Date
        if !force, let last, now().timeIntervalSince(last) < minCheckInterval {
            applyLatest(defaults.string(forKey: Self.cachedVersionKey),
                        urlString: defaults.string(forKey: Self.cachedURLKey))
            return
        }

        guard let result = await fetchLookup() else {
            // Network failed — fall back to any cached result so offline launches still notify.
            applyLatest(defaults.string(forKey: Self.cachedVersionKey),
                        urlString: defaults.string(forKey: Self.cachedURLKey))
            return
        }

        defaults.set(now(), forKey: Self.lastCheckKey)
        defaults.set(result.version, forKey: Self.cachedVersionKey)
        defaults.set(result.storeURL?.absoluteString, forKey: Self.cachedURLKey)
        applyLatest(result.version, urlString: result.storeURL?.absoluteString)
    }

    private func applyLatest(_ version: String?, urlString: String?) {
        guard let version else { return }
        latestVersion = version
        storeURL = urlString.flatMap(URL.init(string:))
        updateAvailable = Self.isVersion(version, newerThan: currentVersion)
    }

    private struct LookupResult { let version: String; let storeURL: URL? }

    private func fetchLookup() async -> LookupResult? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        var items = [URLQueryItem(name: "bundleId", value: bundleID)]
        if let country { items.append(URLQueryItem(name: "country", value: country)) }
        components?.queryItems = items
        guard let url = components?.url else { return nil }

        do {
            let (data, _) = try await session.data(from: url)
            let payload = try JSONDecoder().decode(LookupPayload.self, from: data)
            guard let app = payload.results.first, let version = app.version else { return nil }
            let store = app.trackViewUrl.flatMap(URL.init(string:))
                ?? app.trackId.map { URL(string: "https://apps.apple.com/app/id\($0)") ?? nil } ?? nil
            return LookupResult(version: version, storeURL: store)
        } catch {
            return nil
        }
    }

    private struct LookupPayload: Decodable {
        let results: [App]
        struct App: Decodable {
            let version: String?
            let trackViewUrl: String?
            let trackId: Int?
        }
    }

    /// Numeric, component-wise version comparison. Handles "1.10" > "1.9".
    static func isVersion(_ a: String, newerThan b: String) -> Bool {
        let lhs = a.split(separator: ".").map { Int($0) ?? 0 }
        let rhs = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(lhs.count, rhs.count) {
            let x = i < lhs.count ? lhs[i] : 0
            let y = i < rhs.count ? rhs[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}

extension Bundle {
    /// `CFBundleShortVersionString` (the user-facing marketing version).
    var appShortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
    }
}

// MARK: - SwiftUI presentation

private struct UpdateAvailableModifier: ViewModifier {
    @State private var checker = UpdateChecker()
    @State private var showingPrompt = false
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        content
            .task {
                await checker.check()
                if checker.updateAvailable { showingPrompt = true }
            }
            .alert("Update Available", isPresented: $showingPrompt) {
                if let url = checker.storeURL {
                    Button("Update") { openURL(url) }
                }
                Button("Not Now", role: .cancel) {}
            } message: {
                if let version = checker.latestVersion {
                    Text("Version \(version) is available on the App Store with the latest fixes and improvements.")
                }
            }
    }
}

extension View {
    /// Notifies the user on launch when a newer version is available on the App Store,
    /// with a one-tap link to update. Backend-free and reusable across apps.
    func checkForAppUpdate() -> some View {
        modifier(UpdateAvailableModifier())
    }
}
