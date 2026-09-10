import SwiftUI
import SafariServices

/// Apple's in-app Safari (`SFSafariViewController`) wrapped for SwiftUI.
///
/// This is the compliant way to let people browse YouTube *inside* the app:
/// it's a real Safari session (YouTube's own site, controls, ads, sign-in) shown
/// as a sheet — not a reframed/scraped copy of the Service. From here the user can
/// use Share → TubeTrainer to save a video without leaving the app.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var onFinish: (() -> Void)?

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let controller = SFSafariViewController(url: url, configuration: config)
        controller.preferredControlTintColor = UIColor(TTColor.brandRed)
        controller.dismissButtonStyle = .done
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onFinish: (() -> Void)?
        init(onFinish: (() -> Void)?) { self.onFinish = onFinish }
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onFinish?()
        }
    }
}
