import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var appState = AppState()

    var body: some View {
        Group {
            if settings.onboardingComplete {
                MainTabView()
                    .environment(appState)
                    .fullScreenCover(isPresented: Binding(
                        get: { appState.showingActiveWorkout },
                        set: { appState.showingActiveWorkout = $0 }
                    )) {
                        ActiveWorkoutContainer(sessionID: appState.activeSessionID)
                            .environment(appState)
                    }
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(TTAnim.gentle, value: settings.onboardingComplete)
        .onAppear {
            resumeInProgressIfNeeded()
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let idx = args.firstIndex(of: "-appearance"), idx + 1 < args.count,
               let pref = AppearancePreference(rawValue: args[idx + 1]) {
                settings.appearance = pref
            }
            if let idx = args.firstIndex(of: "-tab"), idx + 1 < args.count {
                switch args[idx + 1] {
                case "library": appState.selectedTab = .library
                case "history": appState.selectedTab = .history
                case "you": appState.selectedTab = .you
                default: break
                }
            }
            #endif
        }
    }

    /// If a workout was left in progress, keep its id ready so Today can offer "Continue".
    private func resumeInProgressIfNeeded() {
        if let session = WorkoutCoordinator.inProgressSession(context: context) {
            appState.activeSessionID = session.id
        }
        #if DEBUG
        // Dev affordance: auto-open an active workout for visual verification.
        // Waits for seeding (which runs in .task) to populate templates.
        if ProcessInfo.processInfo.arguments.contains("-openActive") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard appState.activeSessionID == nil || appState.showingActiveWorkout == false,
                      let template = (try? context.fetch(FetchDescriptor<WorkoutTemplate>()))?
                          .sorted(by: { $0.ordering < $1.ordering }).first else { return }
                let session = WorkoutCoordinator.start(from: template, context: context)
                appState.resume(sessionID: session.id)
            }
        }
        #endif
    }
}

// MARK: - Main tab bar

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "bolt.fill") }
                .tag(AppState.Tab.today)

            LibraryView()
                .tabItem { Label("Library", systemImage: "square.stack.3d.up.fill") }
                .tag(AppState.Tab.library)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(AppState.Tab.history)

            YouView()
                .tabItem { Label("You", systemImage: "person.fill") }
                .tag(AppState.Tab.you)
        }
        .tint(TTColor.brandRed)
    }
}
