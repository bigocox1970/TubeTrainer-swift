import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Principal class for the Share Extension. Extracts a YouTube URL from the
/// shared item and hosts a SwiftUI picker to save it as a coach — writing to the
/// same App Group SwiftData store the app uses.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        extractURL { [weak self] urlString in
            DispatchQueue.main.async { self?.present(with: urlString) }
        }
    }

    private func present(with urlString: String?) {
        let container = PersistenceController.makeContainer()
        let root = ShareRootView(
            rawURL: urlString,
            onClose: { [weak self] in self?.finish() }
        )
        .modelContainer(container)

        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    // MARK: URL extraction

    private func extractURL(completion: @escaping (String?) -> Void) {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let providers = item.attachments else {
            completion(nil); return
        }

        let urlType = UTType.url.identifier
        let textType = UTType.plainText.identifier

        // Prefer a real URL attachment; fall back to shared text containing a link.
        for provider in providers where provider.hasItemConformingToTypeIdentifier(urlType) {
            provider.loadItem(forTypeIdentifier: urlType, options: nil) { data, _ in
                if let url = data as? URL { completion(url.absoluteString) }
                else if let s = data as? String { completion(s) }
                else { completion(nil) }
            }
            return
        }
        for provider in providers where provider.hasItemConformingToTypeIdentifier(textType) {
            provider.loadItem(forTypeIdentifier: textType, options: nil) { data, _ in
                completion(data as? String)
            }
            return
        }
        completion(nil)
    }
}
