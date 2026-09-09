import XCTest
import SwiftData
@testable import TubeTrainer

@MainActor
final class BackupTests: XCTestCase {

    private func populatedContext() -> ModelContext {
        let context = TestStore.makeContext()
        CatalogSeeder.seedCatalog(context)
        try? context.save()

        // Attach a coaching source + build a template + complete a session.
        let exercise = CatalogSeeder.exercise(named: "Barbell Bench Press", in: context)!
        let source = CoachingSource(canonicalURL: "https://www.youtube.com/watch?v=abc123DEF_-",
                                    videoID: "abc123DEF_-", contentType: .video,
                                    title: "Bench form", channelName: "Coach", startSeconds: 42)
        source.exercise = exercise
        context.insert(source)
        exercise.coachingSources.append(source)

        let templates = CatalogSeeder.buildTemplates(for: .pushPullLegs, in: context)
        let session = WorkoutCoordinator.start(from: templates[0], context: context)
        session.orderedExercises.first?.orderedSets.first?.weight = 80
        session.orderedExercises.first?.orderedSets.first?.reps = 8
        session.orderedExercises.first?.orderedSets.first?.completedAt = .now
        WorkoutCoordinator.finish(session, context: context)

        context.insert(Coach(name: "Jeff Nippard"))
        try? context.save()
        return context
    }

    func testExportImportRoundTrip() throws {
        let source = populatedContext()
        let data = try BackupService.export(context: source, unit: .kg)

        // Validate then import into a fresh store.
        let file = try BackupService.validate(data)
        XCTAssertEqual(file.version, BackupFile.currentVersion)
        XCTAssertGreaterThan(file.exercises.count, 40)
        XCTAssertEqual(file.templates.count, 3)
        XCTAssertEqual(file.sessions.count, 1)
        XCTAssertEqual(file.coaches.count, 1)

        let fresh = TestStore.makeContext()
        let restored = try BackupService.importBackup(file, mode: .replace, context: fresh)
        XCTAssertGreaterThan(restored, 0)

        // Coaching source survived with start time.
        let bench = CatalogSeeder.exercise(named: "Barbell Bench Press", in: fresh)
        XCTAssertEqual(bench?.primaryCoach?.startSeconds, 42)

        // Session + set survived.
        let sessions = try fresh.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.completedSetCount, 1)
    }

    func testInvalidBackupRejected() {
        let notJSON = Data("this is not json".utf8)
        XCTAssertThrowsError(try BackupService.validate(notJSON)) { error in
            guard case BackupError.notJSON = error else {
                return XCTFail("Expected .notJSON, got \(error)")
            }
        }
    }

    func testUnsupportedVersionRejected() throws {
        // Hand-craft a future-version backup.
        let json = """
        {"version": 999, "exportedAt": "2026-01-01T00:00:00Z", "appVersion": "9.0",
         "weightUnit": "kg", "exercises": [], "coaches": [], "templates": [], "sessions": []}
        """
        let data = Data(json.utf8)
        XCTAssertThrowsError(try BackupService.validate(data)) { error in
            guard case BackupError.unsupportedVersion(let v) = error else {
                return XCTFail("Expected .unsupportedVersion, got \(error)")
            }
            XCTAssertEqual(v, 999)
        }
    }

    func testMergeDoesNotDuplicate() throws {
        let source = populatedContext()
        let data = try BackupService.export(context: source, unit: .kg)
        let file = try BackupService.validate(data)

        // Import the same backup twice into a fresh store with merge.
        let fresh = TestStore.makeContext()
        _ = try BackupService.importBackup(file, mode: .merge, context: fresh)
        _ = try BackupService.importBackup(file, mode: .merge, context: fresh)

        let sessions = try fresh.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertEqual(sessions.count, 1, "Merge must not duplicate by id")
        let coaches = try fresh.fetch(FetchDescriptor<Coach>())
        XCTAssertEqual(coaches.count, 1)
    }
}
