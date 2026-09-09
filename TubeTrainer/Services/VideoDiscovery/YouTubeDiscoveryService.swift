import Foundation

/// Compliant YouTube integration.
///
/// - URL resolution & single-video metadata use the public **oEmbed** endpoint,
///   which needs no API key and returns title / author / thumbnail.
/// - Free-text search uses the **YouTube Data API v3** *only* when the user has
///   supplied their own key (Settings). Without a key, callers get `.notConfigured`
///   and the UI offers a compliant "Search on YouTube" web fallback.
///
/// We never download, mirror, or redistribute video content.
final class YouTubeDiscoveryService: VideoDiscoveryService {

    private let session: URLSession
    private let apiKeyProvider: () -> String

    init(session: URLSession = .shared, apiKeyProvider: @escaping () -> String) {
        self.session = session
        self.apiKeyProvider = apiKeyProvider
    }

    private var apiKey: String {
        apiKeyProvider().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSearch: Bool { !apiKey.isEmpty }

    // MARK: Search (Data API v3)

    func searchVideos(query: String) async throws -> [VideoResult] {
        try await search(query: query, duration: nil, markAsShort: false)
    }

    func searchShortForm(query: String) async throws -> [VideoResult] {
        // "short" = < 4 min. Good proxy for concise instructional clips/Shorts.
        try await search(query: query, duration: "short", markAsShort: true)
    }

    func videosForCoach(channelID: String, query: String) async throws -> [VideoResult] {
        try await search(query: query, duration: nil, markAsShort: false, channelID: channelID)
    }

    private func search(query: String, duration: String?, markAsShort: Bool, channelID: String? = nil) async throws -> [VideoResult] {
        guard !apiKey.isEmpty else { throw VideoDiscoveryError.notConfigured }

        var comps = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        var items = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "20"),
            URLQueryItem(name: "safeSearch", value: "moderate"),
            URLQueryItem(name: "key", value: apiKey),
        ]
        if let duration { items.append(URLQueryItem(name: "videoDuration", value: duration)) }
        if let channelID { items.append(URLQueryItem(name: "channelId", value: channelID)) }
        comps.queryItems = items

        let data = try await get(comps.url!)

        struct SearchResponse: Decodable {
            struct Item: Decodable {
                struct ID: Decodable { let videoId: String? }
                struct Snippet: Decodable {
                    let title: String
                    let channelTitle: String
                    let channelId: String
                    struct Thumbs: Decodable {
                        struct T: Decodable { let url: String }
                        let medium: T?
                        let high: T?
                        let `default`: T?
                    }
                    let thumbnails: Thumbs
                }
                let id: ID
                let snippet: Snippet
            }
            let items: [Item]
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.items.compactMap { item -> VideoResult? in
            guard let vid = item.id.videoId else { return nil }
            let s = item.snippet
            let thumb = s.thumbnails.high?.url ?? s.thumbnails.medium?.url ?? s.thumbnails.default?.url
            let type: VideoContentType = markAsShort ? .short : .video
            return VideoResult(
                videoID: vid,
                title: s.title.decodingHTMLEntities,
                channelName: s.channelTitle.decodingHTMLEntities,
                channelID: s.channelId,
                thumbnailURL: thumb,
                contentType: type,
                canonicalURL: YouTubeURL.canonical(id: vid, contentType: type),
                startSeconds: nil
            )
        }
    }

    // MARK: Resolve / metadata (oEmbed — keyless)

    func resolveVideo(url: String) async throws -> VideoResult {
        guard let parsed = YouTubeURL.parse(url) else { throw VideoDiscoveryError.invalidURL }
        var result = try await metadata(videoID: parsed.videoID, contentType: parsed.contentType)
        result.startSeconds = parsed.startSeconds
        result.canonicalURL = parsed.canonicalURL
        return result
    }

    func metadata(videoID: String, contentType: VideoContentType) async throws -> VideoResult {
        let canonical = YouTubeURL.canonical(id: videoID, contentType: contentType)
        var comps = URLComponents(string: "https://www.youtube.com/oembed")!
        comps.queryItems = [
            URLQueryItem(name: "url", value: canonical),
            URLQueryItem(name: "format", value: "json"),
        ]

        struct OEmbed: Decodable {
            let title: String
            let author_name: String
            let author_url: String?
            let thumbnail_url: String?
        }

        do {
            let data = try await get(comps.url!)
            let o = try JSONDecoder().decode(OEmbed.self, from: data)
            return VideoResult(
                videoID: videoID,
                title: o.title,
                channelName: o.author_name,
                channelID: nil,
                thumbnailURL: o.thumbnail_url ?? YouTubeURL.thumbnailURL(id: videoID),
                contentType: contentType,
                canonicalURL: canonical,
                startSeconds: nil
            )
        } catch let e as VideoDiscoveryError {
            // oEmbed returns 401/404 for private/removed videos.
            if case .server = e { throw VideoDiscoveryError.notFound }
            throw e
        }
    }

    // MARK: Networking

    private func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return data }
            switch http.statusCode {
            case 200...299: return data
            case 401, 404: throw VideoDiscoveryError.notFound
            case 403: throw VideoDiscoveryError.quotaExceeded
            default: throw VideoDiscoveryError.server("HTTP \(http.statusCode)")
            }
        } catch let e as VideoDiscoveryError {
            throw e
        } catch let e as URLError {
            if e.code == .notConnectedToInternet || e.code == .networkConnectionLost {
                throw VideoDiscoveryError.offline
            }
            throw VideoDiscoveryError.server(e.localizedDescription)
        }
    }
}

// MARK: - HTML entity decoding (API returns &amp; &#39; etc.)

private extension String {
    var decodingHTMLEntities: String {
        guard contains("&") else { return self }
        let replacements: [String: String] = [
            "&amp;": "&", "&#39;": "'", "&quot;": "\"", "&lt;": "<",
            "&gt;": ">", "&#38;": "&", "&apos;": "'",
        ]
        var s = self
        for (k, v) in replacements { s = s.replacingOccurrences(of: k, with: v) }
        return s
    }
}
