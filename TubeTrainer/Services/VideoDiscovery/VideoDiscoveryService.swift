import Foundation

// MARK: - Result model

/// A discovered piece of coaching content. Reference/metadata only — never the media.
struct VideoResult: Identifiable, Equatable, Hashable {
    var id: String { videoID }
    var videoID: String
    var title: String
    var channelName: String
    var channelID: String?
    var thumbnailURL: String?
    var contentType: VideoContentType
    var canonicalURL: String
    var startSeconds: Int?

    func makeCoachingSource(isPrimary: Bool = true) -> CoachingSource {
        CoachingSource(
            canonicalURL: canonicalURL,
            videoID: videoID,
            contentType: contentType,
            title: title,
            channelName: channelName,
            channelID: channelID,
            thumbnailURL: thumbnailURL ?? YouTubeURL.thumbnailURL(id: videoID),
            startSeconds: startSeconds,
            isPrimary: isPrimary
        )
    }
}

// MARK: - Errors

enum VideoDiscoveryError: LocalizedError, Equatable {
    case offline
    case notConfigured           // no API key — search unavailable
    case invalidURL
    case notFound
    case quotaExceeded
    case server(String)

    var errorDescription: String? {
        switch self {
        case .offline: return "You're offline. Connect to search for coaching."
        case .notConfigured: return "In-app search needs a YouTube API key. Add one in Settings, or search on YouTube."
        case .invalidURL: return "That doesn't look like a YouTube link."
        case .notFound: return "This video couldn't be found. It may have been removed or made private."
        case .quotaExceeded: return "Daily YouTube search limit reached. Try again tomorrow or search on YouTube."
        case .server: return "YouTube couldn't be reached right now. Try again."
        }
    }
}

// MARK: - Protocol boundary
//
// Views never touch network code directly. Swap this implementation without
// rewriting any workout/coaching UI.

protocol VideoDiscoveryService: AnyObject {
    /// True when free-text in-app search is available (API key configured).
    var canSearch: Bool { get }

    func searchVideos(query: String) async throws -> [VideoResult]
    func searchShortForm(query: String) async throws -> [VideoResult]
    func videosForCoach(channelID: String, query: String) async throws -> [VideoResult]

    /// Resolve a pasted/shared URL into metadata. Keyless (oEmbed).
    func resolveVideo(url: String) async throws -> VideoResult

    /// Metadata for a known video ID. Keyless (oEmbed).
    func metadata(videoID: String, contentType: VideoContentType) async throws -> VideoResult
}
