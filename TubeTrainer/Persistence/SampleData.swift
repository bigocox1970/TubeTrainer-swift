import Foundation
import SwiftData

/// Optional sample data for development/debug inspection of all UI states (PRD §37).
/// Never runs on a normal production first launch — only via the `-seedSample`
/// launch argument.
@MainActor
enum SampleData {

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-seedSample")
    }

    /// A few real, well-known instructional video IDs used only as *references*
    /// (metadata/thumbnail), never downloaded. Titles are illustrative.
    private struct Coaching {
        let exercise: String
        let videoID: String
        let channel: String
        let title: String
        let start: Int?
        let short: Bool
    }

    // Real, verified instructional videos — referenced by metadata only, never
    // downloaded. Channel/title match the actual content so demo screenshots are honest.
    private static let coaching: [Coaching] = [
        .init(exercise: "Barbell Bench Press", videoID: "vcBig73ojpE", channel: "Jeff Nippard",
              title: "How To Get A Huge Bench Press With Perfect Technique", start: 42, short: false),
        .init(exercise: "Back Squat", videoID: "ultWZbUMPL8", channel: "CrossFit",
              title: "The Back Squat", start: nil, short: false),
        .init(exercise: "Lateral Raise", videoID: "3VcKaXpzqRo", channel: "ScottHermanFitness",
              title: "How To: Dumbbell Side Lateral Raise", start: nil, short: true),
        .init(exercise: "Push-Up", videoID: "IODxDxX7oi4", channel: "Calisthenicmovement",
              title: "The Perfect Push Up | Do It Right!", start: nil, short: false),
        .init(exercise: "Pull-Up", videoID: "eGo4IYlbE5g", channel: "Calisthenicmovement",
              title: "The Perfect Pull Up — Do It Right!", start: nil, short: false),
        .init(exercise: "Deadlift", videoID: "wYREQkVtvEc", channel: "Alan Thrall",
              title: "How To Deadlift: 5 Step Deadlift Setup", start: 18, short: false),
        .init(exercise: "Dip", videoID: "6kALZikXxLc", channel: "Howcast",
              title: "How to Do a Tricep Dip", start: nil, short: false),
        .init(exercise: "Romanian Deadlift", videoID: "r4MzxtBKyNE", channel: "Men's Health",
              title: "How To Perfect Your Deadlift | Form Check", start: nil, short: false),
    ]

    static func seed(context: ModelContext) {
        // Wipe then rebuild for a clean, deterministic sample state.
        try? BackupService.wipeUserContent(context)
        CatalogSeeder.seedCatalog(context)
        try? context.save()

        let templates = CatalogSeeder.buildTemplates(for: .pushPullLegs, in: context)

        // Attach sample coaching.
        for c in coaching {
            guard let exercise = CatalogSeeder.exercise(named: c.exercise, in: context) else { continue }
            let source = CoachingSource(
                canonicalURL: c.short ? YouTubeURL.shortURL(c.videoID) : YouTubeURL.watchURL(c.videoID, start: c.start),
                videoID: c.videoID,
                contentType: c.short ? .short : .video,
                title: c.title, channelName: c.channel,
                thumbnailURL: YouTubeURL.thumbnailURL(id: c.videoID),
                startSeconds: c.start, isPrimary: true
            )
            source.exercise = exercise
            context.insert(source)
            exercise.coachingSources.append(source)
        }

        // Favorite coaches.
        context.insert(Coach(name: "Jeff Nippard", channelURL: "https://youtube.com/@JeffNippard"))
        context.insert(Coach(name: "ScottHermanFitness", channelURL: "https://youtube.com/@ScottHermanFitness"))
        context.insert(Coach(name: "Calisthenicmovement", channelURL: "https://youtube.com/@calimove"))

        // Representative history: 3 past sessions of the Push template.
        if let push = templates.first(where: { $0.name.contains("Push") }) {
            let calendar = Calendar.current
            let baseWeights: [String: Double] = [
                "Barbell Bench Press": 80, "Dumbbell Shoulder Press": 30,
                "Incline Dumbbell Press": 28, "Lateral Raise": 12,
                "Triceps Pushdown": 25, "Overhead Triceps Extension": 22.5,
            ]
            for weeksAgo in [3, 2, 1] {
                guard let date = calendar.date(byAdding: .day, value: -(weeksAgo * 7), to: .now) else { continue }
                let session = WorkoutSession(workoutTemplateID: push.id, nameSnapshot: push.name,
                                             startedAt: date, completedAt: date.addingTimeInterval(54 * 60))
                context.insert(session)
                for (i, tie) in push.orderedExercises.enumerated() {
                    guard let exercise = tie.exercise else { continue }
                    let exSession = ExerciseSession(exercise: exercise, exerciseNameSnapshot: exercise.name, order: i)
                    exSession.workoutSession = session
                    context.insert(exSession)
                    let base = baseWeights[exercise.name] ?? 20
                    // Progressive overload across weeks.
                    let weight = base + Double(3 - weeksAgo) * 2.5
                    for setNum in 1...3 {
                        let set = WorkoutSet(setNumber: setNum, weight: weight,
                                             reps: 10 - (setNum - 1),
                                             completedAt: date.addingTimeInterval(Double(setNum) * 120))
                        set.exerciseSession = exSession
                        context.insert(set)
                        exSession.sets.append(set)
                    }
                    session.exerciseSessions.append(exSession)
                }
                push.lastTrainedAt = date
            }
        }

        try? context.save()
        AppSettings.shared.onboardingComplete = true
    }
}
