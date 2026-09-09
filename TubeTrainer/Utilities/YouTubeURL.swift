import Foundation

/// Parses and canonicalizes YouTube URLs. Pure value logic — no network.
enum YouTubeURL {

    struct Parsed: Equatable {
        var videoID: String
        var contentType: VideoContentType
        var startSeconds: Int?
        var canonicalURL: String
    }

    /// Attempt to extract a YouTube video/short reference from an arbitrary string.
    static func parse(_ raw: String) -> Parsed? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Allow bare IDs (11 chars, YouTube's canonical length).
        if isLikelyBareID(trimmed) {
            return Parsed(videoID: trimmed, contentType: .video, startSeconds: nil,
                          canonicalURL: watchURL(trimmed))
        }

        guard let comps = urlComponents(from: trimmed) else { return nil }
        let host = (comps.host ?? "").lowercased().replacingOccurrences(of: "www.", with: "")
        let path = comps.path

        var videoID: String?
        var contentType: VideoContentType = .video

        switch host {
        case "youtu.be":
            videoID = firstPathComponent(path)
        case "youtube.com", "m.youtube.com", "youtube-nocookie.com", "music.youtube.com":
            if path == "/watch" {
                videoID = comps.queryItems?.first(where: { $0.name == "v" })?.value
            } else if path.hasPrefix("/shorts/") {
                videoID = pathComponent(path, after: "shorts")
                contentType = .short
            } else if path.hasPrefix("/embed/") {
                videoID = pathComponent(path, after: "embed")
            } else if path.hasPrefix("/live/") {
                videoID = pathComponent(path, after: "live")
            } else if path.hasPrefix("/v/") {
                videoID = pathComponent(path, after: "v")
            }
        default:
            return nil
        }

        guard let id = videoID, isValidID(id) else { return nil }

        let start = parseStart(from: comps)
        return Parsed(videoID: id, contentType: contentType, startSeconds: start,
                      canonicalURL: canonical(id: id, contentType: contentType))
    }

    // MARK: Canonical builders

    static func watchURL(_ id: String, start: Int? = nil) -> String {
        var s = "https://www.youtube.com/watch?v=\(id)"
        if let start, start > 0 { s += "&t=\(start)s" }
        return s
    }

    static func shortURL(_ id: String) -> String {
        "https://www.youtube.com/shorts/\(id)"
    }

    static func canonical(id: String, contentType: VideoContentType) -> String {
        contentType == .short ? shortURL(id) : watchURL(id)
    }

    /// Privacy-enhanced embed URL for the in-app player.
    static func embedURL(id: String, start: Int? = nil) -> String {
        var s = "https://www.youtube-nocookie.com/embed/\(id)?playsinline=1&rel=0&modestbranding=1"
        if let start, start > 0 { s += "&start=\(start)" }
        return s
    }

    static func thumbnailURL(id: String) -> String {
        "https://i.ytimg.com/vi/\(id)/hqdefault.jpg"
    }

    /// A search URL usable in Safari / in-app web when the Data API isn't configured.
    static func searchURL(query: String) -> URL? {
        var comps = URLComponents(string: "https://www.youtube.com/results")
        comps?.queryItems = [URLQueryItem(name: "search_query", value: query)]
        return comps?.url
    }

    static func appURL(for canonical: String) -> URL? {
        // youtube:// deep link opens the native app when installed.
        guard let parsed = parse(canonical) else { return URL(string: canonical) }
        return URL(string: "youtube://\(parsed.videoID)")
    }

    // MARK: Helpers

    static func isValidID(_ id: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        return id.count >= 6 && id.count <= 20 && id.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private static func isLikelyBareID(_ s: String) -> Bool {
        guard !s.contains("/"), !s.contains("."), !s.contains(" ") else { return false }
        return s.count == 11 && isValidID(s)
    }

    private static func urlComponents(from raw: String) -> URLComponents? {
        if let c = URLComponents(string: raw), c.host != nil { return c }
        // Prepend scheme if missing (e.g. "youtu.be/abc").
        return URLComponents(string: "https://\(raw)")
    }

    private static func firstPathComponent(_ path: String) -> String? {
        path.split(separator: "/").first.map(String.init)
    }

    private static func pathComponent(_ path: String, after marker: String) -> String? {
        let parts = path.split(separator: "/").map(String.init)
        guard let idx = parts.firstIndex(of: marker), idx + 1 < parts.count else { return nil }
        return parts[idx + 1]
    }

    private static func parseStart(from comps: URLComponents) -> Int? {
        guard let items = comps.queryItems else { return nil }
        let raw = items.first(where: { $0.name == "t" || $0.name == "start" })?.value
        return parseTimeString(raw)
    }

    /// Parses "90", "90s", "1m30s", "2h3m", "1:30" into seconds.
    static func parseTimeString(_ raw: String?) -> Int? {
        guard let raw, !raw.isEmpty else { return nil }
        if let plain = Int(raw) { return plain }

        // Colon form mm:ss or hh:mm:ss
        if raw.contains(":") {
            let parts = raw.split(separator: ":").map { Int($0) ?? 0 }
            switch parts.count {
            case 2: return parts[0] * 60 + parts[1]
            case 3: return parts[0] * 3600 + parts[1] * 60 + parts[2]
            default: return nil
            }
        }

        // 1h2m3s form
        var total = 0
        var current = ""
        var matched = false
        for ch in raw {
            if ch.isNumber {
                current.append(ch)
            } else {
                let value = Int(current) ?? 0
                switch ch {
                case "h", "H": total += value * 3600; matched = true
                case "m", "M": total += value * 60; matched = true
                case "s", "S": total += value; matched = true
                default: break
                }
                current = ""
            }
        }
        return matched ? total : nil
    }
}
