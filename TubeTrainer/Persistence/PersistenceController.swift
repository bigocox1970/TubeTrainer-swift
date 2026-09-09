import Foundation
import SwiftData

enum PersistenceController {

    static let schema = Schema([
        Exercise.self,
        CoachingSource.self,
        Coach.self,
        WorkoutTemplate.self,
        WorkoutTemplateExercise.self,
        WorkoutSession.self,
        ExerciseSession.self,
        WorkoutSet.self,
    ])

    /// True when running under XCTest. Used to keep a single in-memory container
    /// so the app and the test bundle never create two containers for the same
    /// models (which SwiftData does not support and will trap on).
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTest") != nil
    }

    /// The single process-wide container. Tests share this one.
    static let shared: ModelContainer = makeContainer(inMemory: isRunningTests)

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        if inMemory {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: schema, configurations: [config])
        }

        // Prefer the shared App Group store so the Share Extension and the app
        // read/write the same library.
        if let groupURL = AppGroup.storeURL {
            let groupConfig = ModelConfiguration(schema: schema, url: groupURL)
            if let container = try? ModelContainer(for: schema, configurations: [groupConfig]) {
                return container
            }
            print("[TubeTrainer] App Group store unavailable — falling back to local store.")
        }

        // Fall back to a local on-disk store (persists, but not shared with the
        // extension) so data is never lost if the App Group isn't provisioned.
        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            print("[TubeTrainer] Persistent store failed (\(error)). Falling back to in-memory.")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }
}

// MARK: - Seeding

@MainActor
enum CatalogSeeder {

    /// Ensure the built-in exercise catalog exists. Idempotent — only seeds when empty.
    static func seedIfNeeded(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        guard count == 0 else { return }
        seedCatalog(context)
        try? context.save()
    }

    static func seedCatalog(_ context: ModelContext) {
        for seed in SeedCatalog.exercises {
            let ex = Exercise(
                name: seed.name,
                category: seed.category,
                equipment: seed.equipment,
                aliases: seed.aliases,
                defaultRestSeconds: seed.rest
            )
            context.insert(ex)
        }
    }

    /// Look up a seeded/created exercise by name (used when building templates).
    static func exercise(named name: String, in context: ModelContext) -> Exercise? {
        let normalized = name.ttNormalized
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.normalizedName == normalized }
        )
        return try? context.fetch(descriptor).first
    }

    /// Build workout templates from a training structure, wiring real Exercise rows.
    @discardableResult
    static func buildTemplates(
        for structure: TrainingStructure,
        selectedDays: [(day: String, exercises: [String])]? = nil,
        in context: ModelContext
    ) -> [WorkoutTemplate] {
        let plan = selectedDays ?? SeedCatalog.plan(for: structure)
        var created: [WorkoutTemplate] = []
        for (dayIndex, day) in plan.enumerated() {
            let template = WorkoutTemplate(name: day.day, ordering: dayIndex)
            context.insert(template)
            for (exIndex, exName) in day.exercises.enumerated() {
                guard let ex = exercise(named: exName, in: context) else { continue }
                let tie = WorkoutTemplateExercise(exercise: ex, order: exIndex)
                tie.template = template
                context.insert(tie)
                template.exercises.append(tie)
            }
            created.append(template)
        }
        try? context.save()
        return created
    }
}
