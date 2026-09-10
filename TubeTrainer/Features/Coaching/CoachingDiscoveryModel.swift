import SwiftUI
import Observation

@MainActor
@Observable
final class CoachingDiscoveryModel {
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

    var query: String
    var state: LoadState = .idle
    var pasteURL: String = ""
    var pasteState: LoadState = .idle
    var preferShorts = true

    /// Optional coach filter. nil = search all of YouTube; set = scope to that coach.
    var selectedCoach: Coach?

    init(exerciseName: String, discovery: VideoDiscoveryService) {
        self.exerciseName = exerciseName
        self.discovery = discovery
        self.query = ""
    }

    var canSearchInApp: Bool { discovery.canSearch }

    /// Default "recommended" intent when the user hasn't typed anything.
    var recommendedQuery: String {
        preferShorts ? "\(exerciseName) form shorts" : "\(exerciseName) proper form technique"
    }

    /// The query to hand to a web/Safari search when in-app search isn't available.
    /// (A web search can't constrain by channel, so a coach filter becomes a name scope.)
    var browseQuery: String {
        let q = query.trimmingCharacters(in: .whitespaces)
        let base = q.isEmpty ? exerciseName : q
        if let coach = selectedCoach { return "\(coach.name) \(base)" }
        return q.isEmpty ? recommendedQuery : q
    }

    /// Single entry point. Branches on the optional coach filter and the typed query:
    /// - coach selected + has channel id → results from that channel only
    /// - coach selected, no channel id → name-scoped web search
    /// - no coach, empty query → recommended default
    /// - no coach, typed query → open search across YouTube
    func load(coaches: [Coach] = []) async {
        let q = query.trimmingCharacters(in: .whitespaces)
        if let coach = selectedCoach {
            let base = q.isEmpty ? exerciseName : q
            if let channelID = coach.channelID, !channelID.isEmpty {
                await runCoachSearch(channelID: channelID, query: base)
            } else {
                await runSearch(query: "\(coach.name) \(base)", shorts: false)
            }
            return
        }
        if q.isEmpty {
            await runSearch(query: recommendedQuery, shorts: preferShorts)
        } else {
            await runSearch(query: q, shorts: false)
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

    private func runCoachSearch(channelID: String, query: String) async {
        guard discovery.canSearch else { state = .searchUnavailable; return }
        state = .loading
        do {
            let results = try await discovery.videosForCoach(channelID: channelID, query: query)
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
}
