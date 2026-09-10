import Foundation
import SwiftData

// MARK: - Versioned backup schema (Codable DTOs)
//
// Designed for forward migration: a top-level version gate + flat, ID-keyed
// records. We export user-created content and external video *references* only —
// never downloaded media.

struct BackupFile: Codable, Identifiable {
    var id: String { "\(version)-\(exportedAt.timeIntervalSince1970)" }
    static let currentVersion = 1

    var version: Int
    var exportedAt: Date
    var appVersion: String
    var weightUnit: String

    var exercises: [ExerciseDTO]
    var coaches: [CoachDTO]
    var templates: [TemplateDTO]
    var sessions: [SessionDTO]

    struct ExerciseDTO: Codable {
        var id: UUID
        var name: String
        var category: String
        var equipment: String
        var aliases: [String]
        var isCustom: Bool
        var isFavorite: Bool?
        var notes: String
        var defaultRestSeconds: Int
        var restOverrideSeconds: Int?
        var createdAt: Date
        var coaching: [CoachingDTO]
    }

    struct CoachingDTO: Codable {
        var id: UUID
        var provider: String
        var canonicalURL: String
        var videoID: String?
        var contentType: String
        var title: String
        var channelName: String
        var channelID: String?
        var thumbnailURL: String?
        var startSeconds: Int?
        var isPrimary: Bool
        var createdAt: Date
        var updatedAt: Date
    }

    struct CoachDTO: Codable {
        var id: UUID
        var provider: String
        var channelID: String?
        var name: String
        var channelURL: String?
        var avatarURL: String?
        var isFavorite: Bool
        var createdAt: Date
    }

    struct TemplateDTO: Codable {
        var id: UUID
        var name: String
        var ordering: Int
        var createdAt: Date
        var lastTrainedAt: Date?
        var exercises: [TemplateExerciseDTO]
    }

    struct TemplateExerciseDTO: Codable {
        var id: UUID
        var exerciseID: UUID?
        var order: Int
        var targetSets: Int?
        var targetRepMin: Int?
        var targetRepMax: Int?
    }

    struct SessionDTO: Codable {
        var id: UUID
        var workoutTemplateID: UUID?
        var nameSnapshot: String
        var startedAt: Date
        var completedAt: Date?
        var notes: String
        var exercises: [ExerciseSessionDTO]
    }

    struct ExerciseSessionDTO: Codable {
        var id: UUID
        var exerciseID: UUID?
        var exerciseNameSnapshot: String
        var order: Int
        var notesSnapshot: String
        var sets: [SetDTO]
    }

    struct SetDTO: Codable {
        var id: UUID
        var setNumber: Int
        var weight: Double
        var reps: Int
        var setType: String
        var completedAt: Date?
    }
}

// MARK: - Errors

enum BackupError: LocalizedError {
    case cannotRead
    case notJSON
    case unsupportedVersion(Int)
    case corrupt(String)

    var errorDescription: String? {
        switch self {
        case .cannotRead: return "That file couldn't be opened."
        case .notJSON: return "That doesn't look like a TubeTrainer backup."
        case .unsupportedVersion(let v): return "This backup (v\(v)) was made by a newer version of TubeTrainer. Update the app to import it."
        case .corrupt(let why): return "This backup appears to be damaged. \(why)"
        }
    }
}

enum ImportMode {
    case merge      // keep existing, add/update by ID
    case replace    // wipe user content first
}

// MARK: - Service

@MainActor
enum BackupService {

    private static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    private static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // MARK: Export

    static func export(context: ModelContext, unit: WeightUnit) throws -> Data {
        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let coaches = (try? context.fetch(FetchDescriptor<Coach>())) ?? []
        let templates = (try? context.fetch(FetchDescriptor<WorkoutTemplate>())) ?? []
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []

        let file = BackupFile(
            version: BackupFile.currentVersion,
            exportedAt: .now,
            appVersion: Bundle.main.appVersionString,
            weightUnit: unit.rawValue,
            exercises: exercises.map(dto(for:)),
            coaches: coaches.map(dto(for:)),
            templates: templates.map(dto(for:)),
            sessions: sessions.map(dto(for:))
        )
        return try encoder.encode(file)
    }

    /// Writes the backup to a temp file for the share sheet.
    static func exportToTemporaryFile(context: ModelContext, unit: WeightUnit) throws -> URL {
        let data = try export(context: context, unit: unit)
        let name = "TubeTrainer-Backup-\(Self.fileStamp()).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: Validate (pre-flight, non-destructive)

    static func validate(_ data: Data) throws -> BackupFile {
        let file: BackupFile
        do {
            file = try decoder.decode(BackupFile.self, from: data)
        } catch {
            // Distinguish "not our JSON" from "damaged".
            if (try? JSONSerialization.jsonObject(with: data)) == nil {
                throw BackupError.notJSON
            }
            throw BackupError.corrupt(String(describing: error))
        }
        guard file.version <= BackupFile.currentVersion else {
            throw BackupError.unsupportedVersion(file.version)
        }
        return file
    }

    // MARK: Import

    @discardableResult
    static func importBackup(_ file: BackupFile, mode: ImportMode, context: ModelContext) throws -> Int {
        if mode == .replace {
            try wipeUserContent(context)
        }

        // Index existing rows so merge updates in place rather than duplicating.
        var exerciseByID = index(try context.fetch(FetchDescriptor<Exercise>()), \.id)
        var restored = 0

        // Exercises + coaching sources
        for dto in file.exercises {
            let ex = exerciseByID[dto.id] ?? {
                let new = Exercise(id: dto.id, name: dto.name,
                                   category: MuscleCategory(rawValue: dto.category) ?? .fullBody,
                                   equipment: Equipment(rawValue: dto.equipment) ?? .other,
                                   aliases: dto.aliases, isCustom: dto.isCustom,
                                   isFavorite: dto.isFavorite ?? false, notes: dto.notes,
                                   defaultRestSeconds: dto.defaultRestSeconds,
                                   restOverrideSeconds: dto.restOverrideSeconds, createdAt: dto.createdAt)
                context.insert(new)
                exerciseByID[dto.id] = new
                return new
            }()
            ex.name = dto.name
            ex.normalizedName = dto.name.ttNormalized
            ex.categoryRaw = dto.category
            ex.equipmentRaw = dto.equipment
            ex.aliases = dto.aliases
            ex.isCustom = dto.isCustom
            ex.isFavorite = dto.isFavorite ?? false
            ex.notes = dto.notes
            ex.defaultRestSeconds = dto.defaultRestSeconds
            ex.restOverrideSeconds = dto.restOverrideSeconds

            let existingCoaching = Set(ex.coachingSources.map(\.id))
            for c in dto.coaching where !existingCoaching.contains(c.id) {
                let cs = CoachingSource(id: c.id,
                                        provider: VideoProvider(rawValue: c.provider) ?? .youtube,
                                        canonicalURL: c.canonicalURL, videoID: c.videoID,
                                        contentType: VideoContentType(rawValue: c.contentType) ?? .video,
                                        title: c.title, channelName: c.channelName, channelID: c.channelID,
                                        thumbnailURL: c.thumbnailURL, startSeconds: c.startSeconds,
                                        isPrimary: c.isPrimary, createdAt: c.createdAt, updatedAt: c.updatedAt)
                cs.exercise = ex
                context.insert(cs)
                ex.coachingSources.append(cs)
            }
            restored += 1
        }

        // Coaches
        let existingCoachIDs = Set((try context.fetch(FetchDescriptor<Coach>())).map(\.id))
        for c in file.coaches where !existingCoachIDs.contains(c.id) {
            let coach = Coach(id: c.id, provider: VideoProvider(rawValue: c.provider) ?? .youtube,
                              channelID: c.channelID, name: c.name, channelURL: c.channelURL,
                              avatarURL: c.avatarURL, isFavorite: c.isFavorite, createdAt: c.createdAt)
            context.insert(coach)
            restored += 1
        }

        // Templates
        let existingTemplateIDs = Set((try context.fetch(FetchDescriptor<WorkoutTemplate>())).map(\.id))
        for t in file.templates where !existingTemplateIDs.contains(t.id) {
            let template = WorkoutTemplate(id: t.id, name: t.name, ordering: t.ordering,
                                           createdAt: t.createdAt, lastTrainedAt: t.lastTrainedAt)
            context.insert(template)
            for te in t.exercises {
                let tie = WorkoutTemplateExercise(id: te.id,
                                                  exercise: te.exerciseID.flatMap { exerciseByID[$0] },
                                                  order: te.order, targetSets: te.targetSets,
                                                  targetRepMin: te.targetRepMin, targetRepMax: te.targetRepMax)
                tie.template = template
                context.insert(tie)
                template.exercises.append(tie)
            }
            restored += 1
        }

        // Sessions
        let existingSessionIDs = Set((try context.fetch(FetchDescriptor<WorkoutSession>())).map(\.id))
        for s in file.sessions where !existingSessionIDs.contains(s.id) {
            let session = WorkoutSession(id: s.id, workoutTemplateID: s.workoutTemplateID,
                                         nameSnapshot: s.nameSnapshot, startedAt: s.startedAt,
                                         completedAt: s.completedAt, notes: s.notes)
            context.insert(session)
            for es in s.exercises {
                let exSession = ExerciseSession(id: es.id,
                                                exercise: es.exerciseID.flatMap { exerciseByID[$0] },
                                                exerciseNameSnapshot: es.exerciseNameSnapshot,
                                                order: es.order, notesSnapshot: es.notesSnapshot)
                exSession.workoutSession = session
                context.insert(exSession)
                for st in es.sets {
                    let set = WorkoutSet(id: st.id, setNumber: st.setNumber, weight: st.weight,
                                         reps: st.reps, setType: SetType(rawValue: st.setType) ?? .working,
                                         completedAt: st.completedAt)
                    set.exerciseSession = exSession
                    context.insert(set)
                    exSession.sets.append(set)
                }
                session.exerciseSessions.append(exSession)
            }
            restored += 1
        }

        try context.save()
        return restored
    }

    // MARK: Wipe

    static func wipeUserContent(_ context: ModelContext) throws {
        // Order matters less with cascade rules, but be explicit for safety.
        for s in try context.fetch(FetchDescriptor<WorkoutSession>()) { context.delete(s) }
        for t in try context.fetch(FetchDescriptor<WorkoutTemplate>()) { context.delete(t) }
        for c in try context.fetch(FetchDescriptor<Coach>()) { context.delete(c) }
        for e in try context.fetch(FetchDescriptor<Exercise>()) { context.delete(e) }
        try context.save()
    }

    // MARK: DTO mapping

    private static func dto(for e: Exercise) -> BackupFile.ExerciseDTO {
        .init(id: e.id, name: e.name, category: e.categoryRaw, equipment: e.equipmentRaw,
              aliases: e.aliases, isCustom: e.isCustom, isFavorite: e.isFavorite, notes: e.notes,
              defaultRestSeconds: e.defaultRestSeconds, restOverrideSeconds: e.restOverrideSeconds,
              createdAt: e.createdAt,
              coaching: e.coachingSources.map { c in
                .init(id: c.id, provider: c.providerRaw, canonicalURL: c.canonicalURL, videoID: c.videoID,
                      contentType: c.contentTypeRaw, title: c.title, channelName: c.channelName,
                      channelID: c.channelID, thumbnailURL: c.thumbnailURL, startSeconds: c.startSeconds,
                      isPrimary: c.isPrimary, createdAt: c.createdAt, updatedAt: c.updatedAt)
              })
    }

    private static func dto(for c: Coach) -> BackupFile.CoachDTO {
        .init(id: c.id, provider: c.providerRaw, channelID: c.channelID, name: c.name,
              channelURL: c.channelURL, avatarURL: c.avatarURL, isFavorite: c.isFavorite, createdAt: c.createdAt)
    }

    private static func dto(for t: WorkoutTemplate) -> BackupFile.TemplateDTO {
        .init(id: t.id, name: t.name, ordering: t.ordering, createdAt: t.createdAt, lastTrainedAt: t.lastTrainedAt,
              exercises: t.orderedExercises.map { te in
                .init(id: te.id, exerciseID: te.exercise?.id, order: te.order,
                      targetSets: te.targetSets, targetRepMin: te.targetRepMin, targetRepMax: te.targetRepMax)
              })
    }

    private static func dto(for s: WorkoutSession) -> BackupFile.SessionDTO {
        .init(id: s.id, workoutTemplateID: s.workoutTemplateID, nameSnapshot: s.nameSnapshot,
              startedAt: s.startedAt, completedAt: s.completedAt, notes: s.notes,
              exercises: s.orderedExercises.map { es in
                .init(id: es.id, exerciseID: es.exercise?.id, exerciseNameSnapshot: es.exerciseNameSnapshot,
                      order: es.order, notesSnapshot: es.notesSnapshot,
                      sets: es.orderedSets.map { st in
                        .init(id: st.id, setNumber: st.setNumber, weight: st.weight, reps: st.reps,
                              setType: st.setTypeRaw, completedAt: st.completedAt)
                      })
              })
    }

    // MARK: Helpers

    private static func index<T>(_ items: [T], _ key: (T) -> UUID) -> [UUID: T] {
        Dictionary(items.map { (key($0), $0) }, uniquingKeysWith: { a, _ in a })
    }

    private static func fileStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return f.string(from: .now)
    }
}

extension Bundle {
    var appVersionString: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
