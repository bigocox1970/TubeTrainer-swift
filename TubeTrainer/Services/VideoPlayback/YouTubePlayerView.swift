import SwiftUI
import WebKit

/// Compliant embedded YouTube player using the privacy-enhanced iframe embed.
/// Preserves YouTube branding/controls. We never download or proxy media.
struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    var startSeconds: Int?
    /// Called when the embed fails to load so SwiftUI can show a fallback.
    var onFailure: (() -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(onFailure: onFailure) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        loadEmbed(into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onFailure = onFailure
    }

    private func loadEmbed(into webView: WKWebView) {
        let embed = YouTubeURL.embedURL(id: videoID, start: startSeconds)
        // Wrap in minimal responsive HTML so the iframe fills the view edge-to-edge.
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <style>
          * { margin:0; padding:0; }
          html,body { background:#000; height:100%; overflow:hidden; }
          .wrap { position:relative; width:100%; height:100%; }
          iframe { position:absolute; top:0; left:0; width:100%; height:100%; border:0; }
        </style>
        </head>
        <body>
          <div class="wrap">
            <iframe src="\(embed)"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowfullscreen></iframe>
          </div>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var onFailure: (() -> Void)?
        init(onFailure: (() -> Void)?) { self.onFailure = onFailure }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onFailure?()
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onFailure?()
        }
    }
}
