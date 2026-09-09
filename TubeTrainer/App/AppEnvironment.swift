import SwiftUI
import Observation

/// Root dependency container. Injected into the environment so views resolve
/// services (video discovery, settings) without touching concrete network code.
@Observable
@MainActor
final class AppEnvironment {
    let settings: AppSettings
    let discovery: VideoDiscoveryService

    init(settings: AppSettings = .shared) {
        self.settings = settings
        self.discovery = YouTubeDiscoveryService(apiKeyProvider: { settings.youtubeAPIKey })
    }
}
