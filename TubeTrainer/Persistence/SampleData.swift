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
        let thumb: String   // hosted, brand-safe thumbnail (no real YouTuber)
    }

    // Demo coaching uses made-up coaches ("Form First" etc.) and brand-safe hosted
    // thumbnails so marketing screenshots never show a real YouTuber's likeness.
    // videoIDs remain valid references (never shown in screenshots) for link fidelity.
    private static let bench = "https://tubetrainer.app/coach/bench-press.png"
    private static let dead = "https://tubetrainer.app/coach/dead-lift.png"
    private static let shoulder = "https://tubetrainer.app/coach/dumbell-shoulder-press.png"
    private static let coaching: [Coaching] = [
        .init(exercise: "Barbell Bench Press", videoID: "vcBig73ojpE", channel: "Form First",
              title: "How To Bench Press With Perfect Technique", start: 42, short: false, thumb: bench),
        .init(exercise: "Back Squat", videoID: "ultWZbUMPL8", channel: "Lift Lab",
              title: "The Back Squat, Step by Step", start: nil, short: false, thumb: dead),
        .init(exercise: "Lateral Raise", videoID: "3VcKaXpzqRo", channel: "Move Well",
              title: "Dumbbell Lateral Raise — Do It Right", start: nil, short: true, thumb: shoulder),
        .init(exercise: "Push-Up", videoID: "IODxDxX7oi4", channel: "Form First",
              title: "The Perfect Push-Up", start: nil, short: false, thumb: bench),
        .init(exercise: "Pull-Up", videoID: "eGo4IYlbE5g", channel: "Move Well",
              title: "The Perfect Pull-Up", start: nil, short: false, thumb: dead),
        .init(exercise: "Deadlift", videoID: "wYREQkVtvEc", channel: "Lift Lab",
              title: "Deadlift Setup in 5 Steps", start: 18, short: false, thumb: dead),
        .init(exercise: "Dip", videoID: "6kALZikXxLc", channel: "Form First",
              title: "How To Do a Triceps Dip", start: nil, short: false, thumb: bench),
        .init(exercise: "Romanian Deadlift", videoID: "r4MzxtBKyNE", channel: "Lift Lab",
              title: "Romanian Deadlift Form Check", start: nil, short: false, thumb: dead),
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
                thumbnailURL: c.thumb,
                startSeconds: c.start, isPrimary: true
            )
            source.exercise = exercise
            context.insert(source)
            exercise.coachingSources.append(source)
        }

        // Favorite coaches.
        context.insert(Coach(name: "Form First", channelURL: "https://youtube.com/@FormFirst"))
        context.insert(Coach(name: "Lift Lab", channelURL: "https://youtube.com/@LiftLab"))
        context.insert(Coach(name: "Move Well", channelURL: "https://youtube.com/@MoveWell"))

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
