import SwiftUI
import SwiftData

@main
struct TubeTrainerApp: App {
    @State private var settings = AppSettings.shared
    @State private var appEnvironment = AppEnvironment()
    private let container = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(appEnvironment)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(TTColor.brandRed)
                .task { await seed() }
        }
        .modelContainer(container)
    }

    @MainActor
    private func seed() async {
        // Tests drive their own data state on the shared container.
        if PersistenceController.isRunningTests { return }
        if SampleData.isRequested {
            SampleData.seed(context: container.mainContext)
        } else {
            CatalogSeeder.seedIfNeeded(container.mainContext)
        }
    }
}
