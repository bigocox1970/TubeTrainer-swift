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
        try? context.save()
        return source
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
