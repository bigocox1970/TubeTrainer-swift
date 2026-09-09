import Foundation
import SwiftData
@testable import TubeTrainer

/// SwiftData does not support two `ModelContainer`s for the same models in one
/// process. Because the unit-test bundle is hosted inside the app, tests must
/// reuse the app's single shared (in-memory, under test) container rather than
/// creating their own. Each call returns the shared context wiped clean for
/// isolation.
@MainActor
enum TestStore {
    static func makeContext() -> ModelContext {
        let context = PersistenceController.shared.mainContext
        try? BackupService.wipeUserContent(context)
        return context
    }
}
