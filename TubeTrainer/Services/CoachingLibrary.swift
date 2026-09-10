import Foundation
import SwiftData

/// Shared coaching-attach logic used by the app and the Share Extension so both
/// save a coach the same way (new source becomes primary, others demoted).
@MainActor
enum CoachingLibrary {
    @discardableResult
    static func attach(_ result: VideoResult, to exercise: Exercise, context: ModelContext) -> CoachingSource {
        for existing in exercise.coachingSources { existing.isPrimary = false }
        let source = result.makeCoachingSource(isPrimary: true)
        source.exercise = exercise
        context.insert(source)
        exercise.coachingSources.append(source)
        // Saving a video from a channel adds that channel to My Coaches (once).
        ensureCoach(name: result.channelName, channelID: result.channelID, context: context)
        try? context.save()
        return source
    }

    /// Remove the exercise's current coach. If other saved videos exist, the most
    /// recent is promoted to primary; otherwise the exercise returns to no coach.
    static func removePrimaryCoach(from exercise: Exercise, context: ModelContext) {
        guard let primary = exercise.primaryCoach else { return }
        exercise.coachingSources.removeAll { $0.id == primary.id }
        context.delete(primary)
        if let next = exercise.coachingSources.max(by: { $0.createdAt < $1.createdAt }) {
            next.isPrimary = true
        }
        try? context.save()
    }

    /// Add a channel to My Coaches if it isn't already there (matched by channel id,
    /// else by name). No-op for empty channel names (e.g. an unresolved paste).
    static func ensureCoach(name: String, channelID: String?, context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let existing = (try? context.fetch(FetchDescriptor<Coach>())) ?? []
        let alreadyThere = existing.contains { coach in
            if let channelID, let cid = coach.channelID, !cid.isEmpty { return cid == channelID }
            return coach.name.caseInsensitiveCompare(trimmed) == .orderedSame
        }
        guard !alreadyThere else { return }
        context.insert(Coach(channelID: channelID, name: trimmed))
    }

    /// Build a VideoResult from a parsed URL without a network call (extension-safe).
    static func result(from parsed: YouTubeURL.Parsed) -> VideoResult {
        VideoResult(
            videoID: parsed.videoID,
            title: "",
            channelName: "",
            channelID: nil,
            thumbnailURL: YouTubeURL.thumbnailURL(id: parsed.videoID),
            contentType: parsed.contentType,
            canonicalURL: parsed.canonicalURL,
            startSeconds: parsed.startSeconds
        )
    }
}
