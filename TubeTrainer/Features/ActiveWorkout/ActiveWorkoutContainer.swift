import SwiftUI
import SwiftData

/// Resolves the active session id into the live model and presents the workout,
/// or a completion summary. Kept thin so lifecycle is obvious.
struct ActiveWorkoutContainer: View {
    let sessionID: UUID?
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context

    @State private var session: WorkoutSession?
    @State private var completedSession: WorkoutSession?

    var body: some View {
        ZStack {
            if let completedSession {
                WorkoutCompleteView(session: completedSession) {
                    appState.showingActiveWorkout = false
                    appState.activeSessionID = nil
                }
            } else if let session {
                ActiveWorkoutView(session: session,
                                  onFinish: { finish(session) },
                                  onDiscard: { discard(session) })
            } else {
                ZStack { TTBackground(); ProgressView().tint(TTColor.brandRed) }
                    .onAppear(perform: resolve)
            }
        }
    }

    private func resolve() {
        guard let sessionID else { appState.showingActiveWorkout = false; return }
        let descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == sessionID })
        session = try? context.fetch(descriptor).first
        if session == nil { appState.showingActiveWorkout = false }
    }

    private func finish(_ session: WorkoutSession) {
        WorkoutCoordinator.finish(session, context: context)
        TTHaptics.workoutCompleted()
        withAnimation(TTAnim.gentle) {
            completedSession = session
            self.session = nil
        }
    }

    private func discard(_ session: WorkoutSession) {
        WorkoutCoordinator.discard(session, context: context)
        appState.showingActiveWorkout = false
        appState.activeSessionID = nil
    }
}
