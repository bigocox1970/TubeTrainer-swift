import SwiftUI
import Observation

@MainActor
@Observable
final class CoachingDiscoveryModel {
    enum Mode: String, CaseIterable, Identifiable {
        case recommended = "Recommended"
        case myCoaches = "My Coaches"
        case search = "Search"
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .recommended: return "sparkles"
            case .myCoaches: return "person.2.fill"
            case .search: return "magnifyingglass"
            }
        }
    }

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded([VideoResult])
        case empty
        case failed(String)
        /// Search can't run in-app (no API key) — offer web fallback.
        case searchUnavailable
    }

    let exerciseName: String
    private let discovery: VideoDiscoveryService

    var mode: Mode
    var query: String
    var state: LoadState = .idle
    var pasteURL: String = ""
    var pasteState: LoadState = .idle
    var preferShorts = true

    /// The coach filter for My Coaches mode.
    var selectedCoach: Coach?

    init(exerciseName: String, discovery: VideoDiscoveryService, startMode: Mode = .recommended) {
        self.exerciseName = exerciseName
        self.discovery = discovery
        self.mode = startMode
        self.query = exerciseName
    }

    var canSearchInApp: Bool { discovery.canSearch }

    /// Search intent for the exercise.
    var recommendedQuery: String {
        preferShorts ? "\(exerciseName) form shorts" : "\(exerciseName) proper form technique"
    }

    func load(coaches: [Coach] = []) async {
        switch mode {
        case .recommended:
            await runSearch(query: recommendedQuery, shorts: preferShorts)
        case .search:
            let q = query.trimmingCharacters(in: .whitespaces)
            guard !q.isEmpty else { state = .idle; return }
            await runSearch(query: q, shorts: false)
        case .myCoaches:
            await loadCoachContent(coaches: coaches)
        }
    }

    func runSearch(query: String, shorts: Bool) async {
        guard discovery.canSearch else {
            state = .searchUnavailable
            return
        }
        state = .loading
        do {
            let results = shorts
                ? try await discovery.searchShortForm(query: query)
                : try await discovery.searchVideos(query: query)
            state = results.isEmpty ? .empty : .loaded(results)
        } catch let e as VideoDiscoveryError {
            state = e == .notConfigured ? .searchUnavailable : .failed(e.errorDescription ?? "Something went wrong.")
        } catch {
            state = .failed("Something went wrong.")
        }
    }

    private func loadCoachContent(coaches: [Coach]) async {
        guard let coach = selectedCoach ?? coaches.first else {
            state = .empty
            return
        }
        selectedCoach = coach
        guard let channelID = coach.channelID, !channelID.isEmpty else {
            // No channel id stored — can still web-search within the channel name.
            await runSearch(query: "\(coach.name) \(exerciseName)", shorts: false)
            return
        }
        guard discovery.canSearch else { state = .searchUnavailable; return }
        state = .loading
        do {
            let results = try await discovery.videosForCoach(channelID: channelID, query: exerciseName)
            state = results.isEmpty ? .empty : .loaded(results)
        } catch let e as VideoDiscoveryError {
            state = e == .notConfigured ? .searchUnavailable : .failed(e.errorDescription ?? "Something went wrong.")
        } catch {
            state = .failed("Something went wrong.")
        }
    }

    /// Resolve a pasted/shared link via keyless oEmbed.
    func resolvePaste() async -> VideoResult? {
        let raw = pasteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        guard YouTubeURL.parse(raw) != nil else {
            pasteState = .failed(VideoDiscoveryError.invalidURL.errorDescription ?? "Invalid link.")
            return nil
        }
        pasteState = .loading
        do {
            let result = try await discovery.resolveVideo(url: raw)
            pasteState = .idle
            return result
        } catch let e as VideoDiscoveryError {
            pasteState = .failed(e.errorDescription ?? "Couldn't load that link.")
            return nil
        } catch {
            pasteState = .failed("Couldn't load that link.")
            return nil
        }
    }

    func webSearchFallback() {
        let q = mode == .recommended ? recommendedQuery : (query.isEmpty ? exerciseName : query)
        OpenYouTube.search(q)
    }
}
