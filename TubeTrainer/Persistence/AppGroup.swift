import Foundation

/// Shared between the main app and the Share Extension. The SwiftData store lives
/// in this App Group container so both processes read/write the same library.
enum AppGroup {
    static let identifier = "group.app.tubetrainer.ios"

    /// On-disk URL for the shared SwiftData store, or nil if the group container
    /// isn't available (e.g. entitlement not provisioned).
    static var storeURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier)?
            .appendingPathComponent("TubeTrainer.store")
    }
}
