import SwiftUI

/// Opens content in the YouTube app when installed, else the browser.
/// A prominent, compliant fallback everywhere coaching media appears.
@MainActor
enum OpenYouTube {
    static func open(canonicalURL: String) {
        let app = YouTubeURL.appURL(for: canonicalURL)
        if let app, UIApplication.shared.canOpenURL(app) {
            UIApplication.shared.open(app)
        } else if let web = URL(string: canonicalURL) {
            UIApplication.shared.open(web)
        }
    }

    static func search(_ query: String) {
        if let url = YouTubeURL.searchURL(query: query) {
            UIApplication.shared.open(url)
        }
    }
}
