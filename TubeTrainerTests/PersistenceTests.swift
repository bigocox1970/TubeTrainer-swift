import XCTest
import SwiftData
@testable import TubeTrainer

@MainActor
final class PersistenceTests: XCTestCase {

    private func makeContext() -> ModelContext {
        TestStore.makeContext()
    }

    private func seededContext() -> ModelContext {
        let context = makeContext()
        CatalogSeeder.seedCatalog(context)
        try? context.save()
        return context
    }

    func testCatalogSeeds() {
        let context = seededContext()
        let count = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        XCTAssertEqual(count, SeedCatalog.exercises.count)
        XCTAssertGreaterThan(count, 40)
    }

    func testBuildTemplatesWiresExercises() {
        let context = seededContext()
        let templates = CatalogSeeder.buildTemplates(for: .pushPullLegs, in: context)
        XCTAssertEqual(templates.count, 3)
        let push = templates.first { $0.name == "Push Day" }
        XCTAssertNotNil(push)
        XCTAssertEqual(push?.orderedExercises.count, 6)
        XCTAssertNotNil(push?.orderedExercises.first?.exercise)
    }

    func testStartSessionPrefillsFromTemplate() {
        let context = seededContext()
        let template = CatalogSeeder.buildTemplates(for: .pushPullLegs, in: context).first!
        let session = WorkoutCoordinator.start(from: template, context: context)
        XCTAssertEqual(session.orderedExercises.count, template.orderedExercises.count)
        XCTAssertFalse(session.isComplete)
        // Each exercise session pre-creates at least one set.
        XCTAssertTrue(session.orderedExercises.allSatisfy { !$0.orderedSets.isEmpty })
    }

    func testSetLoggingPersistsAndCompletes() {
        let context = seededContext()
        let template = CatalogSeeder.buildTemplates(for: .fullBody, in: context).first!
        let session = WorkoutCoordinator.start(from: template, context: context)
        let exSession = session.orderedExercises.first!
        let set = exSession.orderedSets.first!
        set.weight = 60
        set.reps = 8
        set.completedAt = .now
        try? context.save()

        XCTAssertTrue(set.isCompleted)
        XCTAssertEqual(set.volume, 480)
        XCTAssertEqual(session.completedSetCount, 1)
    }

    func testFinishStripsIncompleteSets() {
        let context = seededContext()
        let template = CatalogSeeder.buildTemplates(for: .fullBody, in: context).first!
        let session = WorkoutCoordinator.start(from: template, context: context)
        // Complete exactly one set on the first exercise.
        let first = session.orderedExercises.first!
        first.orderedSets.first!.completedAt = .now
        first.orderedSets.first!.weight = 50
        first.orderedSets.first!.reps = 5
        try? context.save()

        WorkoutCoordinator.finish(session, context: context)
        XCTAssertTrue(session.isComplete)
        // Only the exercise with a completed set survives; empty ones removed.
        XCTAssertEqual(session.orderedExercises.count, 1)
        XCTAssertEqual(session.orderedExercises.first?.orderedSets.count, 1)
    }

    func testPreviousSessionLookup() {
        let context = seededContext()
        let exercise = CatalogSeeder.exercise(named: "Barbell Bench Press", in: context)!

        // Create a completed past session.
        let past = WorkoutSession(nameSnapshot: "Push", startedAt: .now.addingTimeInterval(-86_400),
                                  completedAt: .now.addingTimeInterval(-86_000))
        context.insert(past)
        let exSession = ExerciseSession(exercise: exercise, exerciseNameSnapshot: exercise.name, order: 0)
        exSession.workoutSession = past
        context.insert(exSession)
        let set = WorkoutSet(setNumber: 1, weight: 80, reps: 8, completedAt: .now.addingTimeInterval(-86_100))
        set.exerciseSession = exSession
        context.insert(set)
        exSession.sets.append(set)
        past.exerciseSessions.append(exSession)
        try? context.save()

        let found = PerformanceStore.lastSession(for: exercise, context: context)
        XCTAssertEqual(found?.orderedSets.first?.weight, 80)
    }

    func testPRDetection() {
        let context = seededContext()
        let exercise = CatalogSeeder.exercise(named: "Back Squat", in: context)!

        // Prior session: 100 x 5
        let prior = completedSession(exercise: exercise, weight: 100, reps: 5, daysAgo: 7, context: context)
        _ = prior
        // New session: 110 x 5 (heaviest set PR)
        let current = completedSession(exercise: exercise, weight: 110, reps: 5, daysAgo: 0, context: context)

        let prs = PerformanceStore.detectPRs(in: current, unit: .kg, context: context)
        XCTAssertTrue(prs.contains { $0.text.contains("Heaviest") })
    }

    @discardableResult
    private func completedSession(exercise: Exercise, weight: Double, reps: Int, daysAgo: Int, context: ModelContext) -> WorkoutSession {
        let date = Date().addingTimeInterval(TimeInterval(-daysAgo * 86_400))
        let session = WorkoutSession(nameSnapshot: "Legs", startedAt: date, completedAt: date.addingTimeInterval(3000))
        context.insert(session)
        let exSession = ExerciseSession(exercise: exercise, exerciseNameSnapshot: exercise.name, order: 0)
        exSession.workoutSession = session
        context.insert(exSession)
        let set = WorkoutSet(setNumber: 1, weight: weight, reps: reps, completedAt: date)
        set.exerciseSession = exSession
        context.insert(set)
        exSession.sets.append(set)
        session.exerciseSessions.append(exSession)
        try? context.save()
        return session
    }
}
