import Foundation
import SwiftData

/// Read helpers for previous performance and personal records.
/// Kept out of views so logging UI never runs fetch logic inline.
@MainActor
enum PerformanceStore {

    /// Most recent *completed* exercise session for an exercise, excluding an optional session.
    static func lastSession(for exercise: Exercise, excluding sessionID: UUID? = nil, context: ModelContext) -> ExerciseSession? {
        let exID = exercise.id
        // NB: don't sort in the FetchDescriptor by \.workoutSession?.startedAt —
        // SwiftData can't resolve a sort keypath through an optional relationship
        // and traps under Release/whole-module optimisation. Sort in memory instead.
        let descriptor = FetchDescriptor<ExerciseSession>(
            predicate: #Predicate { es in
                es.exercise?.id == exID &&
                es.workoutSession?.completedAt != nil
            }
        )
        let results = ((try? context.fetch(descriptor)) ?? [])
            .sorted { ($0.workoutSession?.startedAt ?? .distantPast) > ($1.workoutSession?.startedAt ?? .distantPast) }
        return results.first { $0.workoutSession?.id != sessionID && !$0.orderedSets.isEmpty }
    }

    /// Completed exercise sessions for an exercise, newest first.
    static func history(for exercise: Exercise, limit: Int = 50, context: ModelContext) -> [ExerciseSession] {
        let exID = exercise.id
        // Sort/limit in memory — a FetchDescriptor sort through the optional
        // \.workoutSession?.startedAt keypath traps in Release (see lastSession).
        let descriptor = FetchDescriptor<ExerciseSession>(
            predicate: #Predicate { es in
                es.exercise?.id == exID &&
                es.workoutSession?.completedAt != nil
            }
        )
        return ((try? context.fetch(descriptor)) ?? [])
            .filter { !$0.orderedSets.isEmpty }
            .sorted { ($0.workoutSession?.startedAt ?? .distantPast) > ($1.workoutSession?.startedAt ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: Personal records

    struct Records {
        var heaviestWeight: Double = 0
        var heaviestSet: (weight: Double, reps: Int)?
        var bestEstimated1RM: Double = 0
        var bestSessionVolume: Double = 0
    }

    /// Compute records across all completed history for an exercise.
    static func records(for exercise: Exercise, context: ModelContext) -> Records {
        var r = Records()
        let sessions = history(for: exercise, limit: 500, context: context)
        for session in sessions {
            var sessionVolume: Double = 0
            for set in session.orderedSets where set.isCompleted {
                sessionVolume += set.volume
                if set.weight > r.heaviestWeight {
                    r.heaviestWeight = set.weight
                    r.heaviestSet = (set.weight, set.reps)
                }
                let e1rm = OneRepMax.epley(weight: set.weight, reps: set.reps)
                if e1rm > r.bestEstimated1RM { r.bestEstimated1RM = e1rm }
            }
            if sessionVolume > r.bestSessionVolume { r.bestSessionVolume = sessionVolume }
        }
        return r
    }

    // MARK: PR detection for a just-finished session

    struct PRHighlight: Identifiable {
        let id = UUID()
        let exerciseName: String
        let text: String
    }

    /// Compare a completed session's sets against prior history to surface genuine PRs.
    static func detectPRs(in session: WorkoutSession, unit: WeightUnit, context: ModelContext) -> [PRHighlight] {
        var highlights: [PRHighlight] = []

        for exSession in session.orderedExercises {
            guard let exercise = exSession.exercise else { continue }
            let completed = exSession.orderedSets.filter { $0.isCompleted }
            guard !completed.isEmpty else { continue }

            // Prior records exclude this session.
            let prior = priorRecords(for: exercise, excluding: session.id, context: context)

            let bestWeightThis = completed.map(\.weight).max() ?? 0
            let best1RMThis = completed.map { OneRepMax.epley(weight: $0.weight, reps: $0.reps) }.max() ?? 0
            let volumeThis = completed.reduce(0) { $0 + $1.volume }

            if bestWeightThis > prior.heaviestWeight, bestWeightThis > 0 {
                if let set = completed.filter({ $0.weight == bestWeightThis }).max(by: { $0.reps < $1.reps }) {
                    highlights.append(.init(exerciseName: exercise.name,
                                            text: "Heaviest set — \(TTFormat.weightReps(set.weight, reps: set.reps))"))
                }
            } else if best1RMThis > prior.bestEstimated1RM, prior.bestEstimated1RM > 0 {
                highlights.append(.init(exerciseName: exercise.name,
                                        text: "Est. 1RM \(TTFormat.weight(best1RMThis.rounded(), unit: unit))"))
            }

            if volumeThis > prior.bestSessionVolume, prior.bestSessionVolume > 0 {
                highlights.append(.init(exerciseName: exercise.name, text: "Best volume yet"))
            }
        }
        return highlights
    }

    private static func priorRecords(for exercise: Exercise, excluding sessionID: UUID, context: ModelContext) -> Records {
        var r = Records()
        let exID = exercise.id
        let descriptor = FetchDescriptor<ExerciseSession>(
            predicate: #Predicate { es in
                es.exercise?.id == exID &&
                es.workoutSession?.completedAt != nil
            }
        )
        let sessions = ((try? context.fetch(descriptor)) ?? []).filter { $0.workoutSession?.id != sessionID }
        for session in sessions {
            var sessionVolume: Double = 0
            for set in session.orderedSets where set.isCompleted {
                sessionVolume += set.volume
                if set.weight > r.heaviestWeight { r.heaviestWeight = set.weight }
                let e1rm = OneRepMax.epley(weight: set.weight, reps: set.reps)
                if e1rm > r.bestEstimated1RM { r.bestEstimated1RM = e1rm }
            }
            if sessionVolume > r.bestSessionVolume { r.bestSessionVolume = sessionVolume }
        }
        return r
    }
}
