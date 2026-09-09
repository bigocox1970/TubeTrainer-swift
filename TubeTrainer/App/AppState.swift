import SwiftUI
import SwiftData
import Observation

/// App-wide UI coordination: selected tab + active workout presentation.
@Observable
@MainActor
final class AppState {
    enum Tab: Hashable { case today, library, history, you }

    var selectedTab: Tab = .today

    /// The id of the workout session currently being trained (presented full-screen).
    var activeSessionID: UUID?

    /// Drives the full-screen active-workout takeover.
    var showingActiveWorkout = false

    func resume(sessionID: UUID) {
        activeSessionID = sessionID
        showingActiveWorkout = true
    }
}

/// Creates, resumes and finishes workout sessions. Pure model work — no view state.
@MainActor
enum WorkoutCoordinator {

    /// Fetch an in-progress (not completed) session if one exists.
    static func inProgressSession(context: ModelContext) -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.completedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Start a new session from a template, snapshotting name + exercises.
    static func start(from template: WorkoutTemplate, context: ModelContext) -> WorkoutSession {
        let session = WorkoutSession(workoutTemplateID: template.id, nameSnapshot: template.name)
        context.insert(session)

        for (index, tie) in template.orderedExercises.enumerated() {
            guard let exercise = tie.exercise else { continue }
            let exSession = ExerciseSession(
                exercise: exercise,
                exerciseNameSnapshot: exercise.name,
                order: index,
                notesSnapshot: exercise.notes
            )
            exSession.workoutSession = session
            context.insert(exSession)
            session.exerciseSessions.append(exSession)

            // Pre-create sets from last time (or target sets) so logging is instant.
            let last = PerformanceStore.lastSession(for: exercise, excluding: session.id, context: context)
            let templateSets = tie.targetSets ?? 3
            let count = max(last?.orderedSets.count ?? templateSets, 1)
            for setIndex in 0..<count {
                let prev = last?.orderedSets[safe: setIndex]
                let set = WorkoutSet(
                    setNumber: setIndex + 1,
                    weight: prev?.weight ?? 0,
                    reps: prev?.reps ?? tie.targetRepMax ?? 0
                )
                set.exerciseSession = exSession
                context.insert(set)
                exSession.sets.append(set)
            }
        }

        template.lastTrainedAt = .now
        try? context.save()
        return session
    }

    /// Start an ad-hoc single-exercise session (used from exercise detail "Log").
    static func startQuick(exercise: Exercise, context: ModelContext) -> WorkoutSession {
        let session = WorkoutSession(workoutTemplateID: nil, nameSnapshot: exercise.name)
        context.insert(session)
        let exSession = ExerciseSession(exercise: exercise, exerciseNameSnapshot: exercise.name, order: 0, notesSnapshot: exercise.notes)
        exSession.workoutSession = session
        context.insert(exSession)
        session.exerciseSessions.append(exSession)

        let last = PerformanceStore.lastSession(for: exercise, excluding: session.id, context: context)
        let count = max(last?.orderedSets.count ?? 3, 1)
        for setIndex in 0..<count {
            let prev = last?.orderedSets[safe: setIndex]
            let set = WorkoutSet(setNumber: setIndex + 1, weight: prev?.weight ?? 0, reps: prev?.reps ?? 0)
            set.exerciseSession = exSession
            context.insert(set)
            exSession.sets.append(set)
        }
        try? context.save()
        return session
    }

    /// Finalize a session. Strips empty exercise sessions/sets so history stays clean.
    static func finish(_ session: WorkoutSession, context: ModelContext) {
        for exSession in session.exerciseSessions {
            // Remove sets that were never completed.
            for set in exSession.sets where !set.isCompleted {
                context.delete(set)
            }
        }
        // Remove exercise sessions that ended up with no completed sets.
        for exSession in session.exerciseSessions where exSession.sets.allSatisfy({ !$0.isCompleted }) {
            context.delete(exSession)
        }
        session.completedAt = .now
        try? context.save()
    }

    /// Discard an in-progress session entirely.
    static func discard(_ session: WorkoutSession, context: ModelContext) {
        context.delete(session)
        try? context.save()
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
