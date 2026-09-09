import SwiftUI

/// Simple in-memory image cache so thumbnails never re-download or block the UI.
actor ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func store(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
}

/// Async video thumbnail with graceful placeholder + failure states.
/// Never blocks the main actor; degrades to a branded placeholder offline.
struct TTThumbnail: View {
    let urlString: String?
    var contentType: VideoContentType = .video

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            placeholder
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            }
        }
        .clipped()
        .task(id: urlString) { await load() }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [TTColor.surfaceElevated, TTColor.backgroundSecondary],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Image(systemName: failed ? "wifi.slash" : (contentType == .short ? "play.rectangle.on.rectangle" : "play.rectangle.fill"))
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(TTColor.textTertiary)
        }
    }

    private func load() async {
        image = nil
        failed = false
        guard let urlString, let url = URL(string: urlString) else { failed = true; return }

        if let cached = await ThumbnailCache.shared.image(for: url) {
            image = cached
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let ui = UIImage(data: data) else {
                failed = true
                return
            }
            await ThumbnailCache.shared.store(ui, for: url)
            withAnimation(.easeOut(duration: 0.25)) { image = ui }
        } catch {
            failed = true
        }
    }
}
