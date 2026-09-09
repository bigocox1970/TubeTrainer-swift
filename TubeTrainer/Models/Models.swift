import Foundation
import SwiftData

// MARK: - Exercise

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var normalizedName: String
    var categoryRaw: String
    var equipmentRaw: String
    /// Extra search terms / aliases (e.g. "RDL" for Romanian Deadlift).
    var aliases: [String]
    var isCustom: Bool
    var notes: String
    var defaultRestSeconds: Int
    /// nil = use global default rest.
    var restOverrideSeconds: Int?
    var createdAt: Date

    /// A single exercise can have multiple saved coaching sources; one is primary.
    @Relationship(deleteRule: .cascade, inverse: \CoachingSource.exercise)
    var coachingSources: [CoachingSource]

    init(
        id: UUID = UUID(),
        name: String,
        category: MuscleCategory,
        equipment: Equipment,
        aliases: [String] = [],
        isCustom: Bool = false,
        notes: String = "",
        defaultRestSeconds: Int = 90,
        restOverrideSeconds: Int? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.normalizedName = name.ttNormalized
        self.categoryRaw = category.rawValue
        self.equipmentRaw = equipment.rawValue
        self.aliases = aliases
        self.isCustom = isCustom
        self.notes = notes
        self.defaultRestSeconds = defaultRestSeconds
        self.restOverrideSeconds = restOverrideSeconds
        self.createdAt = createdAt
        self.coachingSources = []
    }

    var category: MuscleCategory {
        get { MuscleCategory(rawValue: categoryRaw) ?? .fullBody }
        set { categoryRaw = newValue.rawValue }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .other }
        set { equipmentRaw = newValue.rawValue }
    }

    var primaryCoach: CoachingSource? {
        coachingSources.first(where: { $0.isPrimary }) ?? coachingSources.first
    }

    var hasCoach: Bool { !coachingSources.isEmpty }

    var effectiveRestSeconds: Int {
        restOverrideSeconds ?? defaultRestSeconds
    }
}

// MARK: - CoachingSource

@Model
final class CoachingSource {
    @Attribute(.unique) var id: UUID
    var exercise: Exercise?
    var providerRaw: String
    var canonicalURL: String
    var videoID: String?
    var contentTypeRaw: String
    var title: String
    var channelName: String
    var channelID: String?
    var thumbnailURL: String?
    var startSeconds: Int?
    var isPrimary: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        provider: VideoProvider = .youtube,
        canonicalURL: String,
        videoID: String? = nil,
        contentType: VideoContentType = .video,
        title: String,
        channelName: String,
        channelID: String? = nil,
        thumbnailURL: String? = nil,
        startSeconds: Int? = nil,
        isPrimary: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.providerRaw = provider.rawValue
        self.canonicalURL = canonicalURL
        self.videoID = videoID
        self.contentTypeRaw = contentType.rawValue
        self.title = title
        self.channelName = channelName
        self.channelID = channelID
        self.thumbnailURL = thumbnailURL
        self.startSeconds = startSeconds
        self.isPrimary = isPrimary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var provider: VideoProvider { VideoProvider(rawValue: providerRaw) ?? .youtube }
    var contentType: VideoContentType {
        get { VideoContentType(rawValue: contentTypeRaw) ?? .video }
        set { contentTypeRaw = newValue.rawValue }
    }
}

// MARK: - Coach (favorite channel)

@Model
final class Coach {
    @Attribute(.unique) var id: UUID
    var providerRaw: String
    var channelID: String?
    var name: String
    var channelURL: String?
    var avatarURL: String?
    var isFavorite: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        provider: VideoProvider = .youtube,
        channelID: String? = nil,
        name: String,
        channelURL: String? = nil,
        avatarURL: String? = nil,
        isFavorite: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.providerRaw = provider.rawValue
        self.channelID = channelID
        self.name = name
        self.channelURL = channelURL
        self.avatarURL = avatarURL
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }
}

// MARK: - WorkoutTemplate

@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var ordering: Int
    var createdAt: Date
    var lastTrainedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplateExercise.template)
    var exercises: [WorkoutTemplateExercise]

    init(
        id: UUID = UUID(),
        name: String,
        ordering: Int = 0,
        createdAt: Date = .now,
        lastTrainedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.ordering = ordering
        self.createdAt = createdAt
        self.lastTrainedAt = lastTrainedAt
        self.exercises = []
    }

    var orderedExercises: [WorkoutTemplateExercise] {
        exercises.sorted { $0.order < $1.order }
    }
}

// MARK: - WorkoutTemplateExercise

@Model
final class WorkoutTemplateExercise {
    @Attribute(.unique) var id: UUID
    var template: WorkoutTemplate?
    var exercise: Exercise?
    var order: Int
    var targetSets: Int?
    var targetRepMin: Int?
    var targetRepMax: Int?

    init(
        id: UUID = UUID(),
        exercise: Exercise?,
        order: Int,
        targetSets: Int? = 3,
        targetRepMin: Int? = 8,
        targetRepMax: Int? = 12
    ) {
        self.id = id
        self.exercise = exercise
        self.order = order
        self.targetSets = targetSets
        self.targetRepMin = targetRepMin
        self.targetRepMax = targetRepMax
    }

    var targetSummary: String? {
        guard let sets = targetSets else { return nil }
        if let lo = targetRepMin, let hi = targetRepMax {
            return lo == hi ? "\(sets) × \(lo)" : "\(sets) × \(lo)–\(hi)"
        }
        return "\(sets) sets"
    }
}

// MARK: - WorkoutSession

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var workoutTemplateID: UUID?
    var nameSnapshot: String
    var startedAt: Date
    var completedAt: Date?
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSession.workoutSession)
    var exerciseSessions: [ExerciseSession]

    init(
        id: UUID = UUID(),
        workoutTemplateID: UUID? = nil,
        nameSnapshot: String,
        startedAt: Date = .now,
        completedAt: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.workoutTemplateID = workoutTemplateID
        self.nameSnapshot = nameSnapshot
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.notes = notes
        self.exerciseSessions = []
    }

    var isComplete: Bool { completedAt != nil }

    var orderedExercises: [ExerciseSession] {
        exerciseSessions.sorted { $0.order < $1.order }
    }

    var durationSeconds: Int {
        let end = completedAt ?? .now
        return max(0, Int(end.timeIntervalSince(startedAt)))
    }

    var completedSetCount: Int {
        exerciseSessions.reduce(0) { $0 + $1.sets.filter { $0.isCompleted }.count }
    }
}

// MARK: - ExerciseSession

@Model
final class ExerciseSession {
    @Attribute(.unique) var id: UUID
    var workoutSession: WorkoutSession?
    var exercise: Exercise?
    /// Snapshot so history reads correctly even if the exercise is renamed/deleted.
    var exerciseNameSnapshot: String
    var order: Int
    var notesSnapshot: String

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.exerciseSession)
    var sets: [WorkoutSet]

    init(
        id: UUID = UUID(),
        exercise: Exercise?,
        exerciseNameSnapshot: String,
        order: Int,
        notesSnapshot: String = ""
    ) {
        self.id = id
        self.exercise = exercise
        self.exerciseNameSnapshot = exerciseNameSnapshot
        self.order = order
        self.notesSnapshot = notesSnapshot
        self.sets = []
    }

    var orderedSets: [WorkoutSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    var displayName: String {
        exercise?.name ?? exerciseNameSnapshot
    }
}

// MARK: - WorkoutSet

@Model
final class WorkoutSet {
    @Attribute(.unique) var id: UUID
    var exerciseSession: ExerciseSession?
    var setNumber: Int
    var weight: Double
    var reps: Int
    var setTypeRaw: String
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double = 0,
        reps: Int = 0,
        setType: SetType = .working,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.setTypeRaw = setType.rawValue
        self.completedAt = completedAt
    }

    var setType: SetType {
        get { SetType(rawValue: setTypeRaw) ?? .working }
        set { setTypeRaw = newValue.rawValue }
    }

    var isCompleted: Bool { completedAt != nil }

    /// Volume in whatever unit weight is stored in.
    var volume: Double { weight * Double(reps) }
}
