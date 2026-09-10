import SwiftUI
import SwiftData
import Observation

/// Holds onboarding selections and materializes the starting workout structure.
@MainActor
@Observable
final class OnboardingModel {
    var step = 0
    var firstName = ""
    var experience: ExperienceLevel = .some
    var structure: TrainingStructure = .pushPullLegs

    /// Per-day exercise selections (editable). Keyed by day name in plan order.
    var days: [DayPlan] = []

    struct DayPlan: Identifiable {
        let id = UUID()
        var name: String
        var exerciseNames: [String]
    }

    let totalSteps = 7

    func loadPlan() {
        let plan = SeedCatalog.plan(for: structure)
        days = plan.map { DayPlan(name: $0.day, exerciseNames: $0.exercises) }
    }

    /// Build templates + set experience-based default targets, then mark complete.
    func finish(context: ModelContext, settings: AppSettings) {
        CatalogSeeder.seedIfNeeded(context)

        let selectedDays = days.map { (day: $0.name, exercises: $0.exerciseNames) }
        let templates = CatalogSeeder.buildTemplates(for: structure, selectedDays: selectedDays, in: context)

        // Experience influences default rep targets (never locks anything).
        let repRange: (Int, Int)
        switch experience {
        case .new: repRange = (8, 12)
        case .some: repRange = (6, 12)
        case .experienced: repRange = (5, 10)
        }
        for template in templates {
            for tie in template.exercises {
                tie.targetRepMin = repRange.0
                tie.targetRepMax = repRange.1
            }
        }
        try? context.save()

        settings.nickname = firstName.trimmingCharacters(in: .whitespaces)
        settings.onboardingComplete = true
        TTHaptics.workoutCompleted()
    }

    func skipToDefaults(context: ModelContext, settings: AppSettings) {
        CatalogSeeder.seedIfNeeded(context)
        CatalogSeeder.buildTemplates(for: .pushPullLegs, in: context)
        settings.onboardingComplete = true
    }
}
