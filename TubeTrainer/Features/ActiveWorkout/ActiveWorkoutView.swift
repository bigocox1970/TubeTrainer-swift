import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    var onFinish: () -> Void
    var onDiscard: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase

    @State private var currentIndex = 0
    @State private var restTimer = RestTimerEngine()
    @State private var elapsed = 0
    @State private var showFinishConfirm = false
    @State private var showDiscardConfirm = false
    @State private var discovering: ExerciseSession?
    @State private var discoveryMode: CoachingDiscoveryModel.Mode = .recommended
    @State private var restExpanded = false

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var exercises: [ExerciseSession] { session.orderedExercises }
    private var currentExercise: ExerciseSession? { exercises[safe: currentIndex] }

    var body: some View {
        ZStack {
            TTBackground()
            VStack(spacing: 0) {
                header
                progressStrip
                if let exSession = currentExercise {
                    exercisePage(exSession)
                } else {
                    emptyWorkout
                }
                bottomBar
            }
            if restTimer.isRunning {
                VStack {
                    Spacer()
                    RestTimerBar(engine: restTimer, onExpand: { withAnimation(TTAnim.standard) { restExpanded = true } })
                        .padding(.horizontal, TTSpace.md)
                        .padding(.bottom, 96)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            if restExpanded {
                RestTimerRechargeView(engine: restTimer) {
                    withAnimation(TTAnim.standard) { restExpanded = false }
                }
                .zIndex(2)
            }
        }
        .animation(TTAnim.standard, value: restTimer.isRunning)
        .onChange(of: restTimer.isRunning) { _, running in
            if !running { withAnimation(TTAnim.standard) { restExpanded = false } }
        }
        .onAppear {
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-activeIndex"), i + 1 < args.count,
               let idx = Int(args[i + 1]), exercises.indices.contains(idx) {
                currentIndex = idx
            }
            // Demo/screenshots: show the expanded recharge rest timer, mid-recovery.
            if args.contains("-restTimer") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    restTimer.debugStart(total: 90, remaining: 34)
                    restExpanded = true
                }
            }
            // Demo/screenshots: mark this exercise's prefilled sets as completed.
            if args.contains("-logSets") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if let ex = exercises[safe: currentIndex] {
                        for set in ex.orderedSets where set.weight > 0 && set.reps > 0 {
                            set.completedAt = .now
                        }
                        try? context.save()
                    }
                }
            }
            #endif
        }
        .onReceive(clock) { _ in elapsed = session.durationSeconds }
        .onChange(of: scenePhase) { _, phase in if phase == .active { restTimer.refresh() } }
        .sheet(item: $discovering) { exSession in
            if let exercise = exSession.exercise {
                CoachingDiscoveryView(exercise: exercise, startMode: discoveryMode) { result in
                    attachCoach(result, to: exercise)
                }
            }
        }
        .confirmationDialog("Finish workout?", isPresented: $showFinishConfirm, titleVisibility: .visible) {
            Button("Finish & Save") { restTimer.skip(); onFinish() }
            Button("Keep training", role: .cancel) {}
        } message: {
            Text("\(session.completedSetCount) sets logged.")
        }
        .confirmationDialog("Discard this workout?", isPresented: $showDiscardConfirm, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { restTimer.skip(); onDiscard() }
            Button("Keep training", role: .cancel) {}
        } message: {
            Text("Nothing from this session will be saved.")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button { showDiscardConfirm = true } label: {
                Image(systemName: "xmark")
                    .font(.headline).foregroundStyle(TTColor.textSecondary)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Discard workout")

            Spacer()
            VStack(spacing: 0) {
                Text(session.nameSnapshot.uppercased())
                    .font(TTFont.caption()).tracking(1.2)
                    .foregroundStyle(TTColor.textSecondary)
                Text(TTFormat.clock(elapsed))
                    .font(TTFont.numeric(20, weight: .semibold))
                    .foregroundStyle(TTColor.textPrimary)
                    .contentTransition(.numericText())
            }
            Spacer()

            Button { showFinishConfirm = true } label: {
                Text("Finish")
                    .font(TTFont.subheadline().weight(.bold))
                    .foregroundStyle(TTColor.brandRed)
                    .frame(height: 40)
                    .padding(.horizontal, TTSpace.sm)
            }
        }
        .padding(.horizontal, TTSpace.md)
        .padding(.top, TTSpace.xs)
    }

    // MARK: Progress strip

    private var progressStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TTSpace.xs) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, ex in
                        let done = ex.orderedSets.contains { $0.isCompleted }
                        Button {
                            withAnimation(TTAnim.quick) { currentIndex = index }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                    .font(.caption2)
                                Text(shortName(ex.displayName))
                                    .font(TTFont.caption())
                                    .lineLimit(1)
                            }
                            .foregroundStyle(index == currentIndex ? .white : (done ? TTColor.success : TTColor.textSecondary))
                            .padding(.horizontal, TTSpace.sm)
                            .padding(.vertical, 7)
                            .background(index == currentIndex ? TTColor.brandRed : TTColor.controlFill, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .id(index)
                    }
                }
                .padding(.horizontal, TTSpace.md)
                .padding(.vertical, TTSpace.sm)
            }
            .onChange(of: currentIndex) { _, new in
                withAnimation(TTAnim.quick) { proxy.scrollTo(new, anchor: .center) }
            }
        }
    }

    private func shortName(_ name: String) -> String {
        name.count > 16 ? String(name.prefix(15)) + "…" : name
    }

    // MARK: Exercise page

    private func exercisePage(_ exSession: ExerciseSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TTSpace.lg) {
                // Identity
                VStack(alignment: .leading, spacing: 4) {
                    Text(exSession.displayName)
                        .font(TTFont.largeTitle())
                        .foregroundStyle(TTColor.textPrimary)
                    if let exercise = exSession.exercise {
                        Text("\(exercise.category.shortName) · \(exercise.equipment.rawValue)")
                            .font(TTFont.subheadline())
                            .foregroundStyle(TTColor.textSecondary)
                    }
                }

                // Coaching
                coachingArea(exSession)

                // Last time + set logger
                SetLoggerView(
                    exSession: exSession,
                    onSetCompleted: { handleSetCompleted(for: exSession) }
                )

                // Notes
                ExerciseNotesView(exSession: exSession)
            }
            .padding(TTSpace.md)
            .padding(.bottom, restTimer.isRunning ? 160 : 100)
            .id(exSession.id)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private func coachingArea(_ exSession: ExerciseSession) -> some View {
        if let exercise = exSession.exercise, let source = exercise.primaryCoach {
            TTVideoHero(source: source,
                        onChangeCoach: { discovering = exSession },
                        onRemoveCoach: { removeCoach(from: exercise) })
        } else {
            TTEmptyCoachView(
                exerciseName: exSession.displayName,
                onRecommended: { discoveryMode = .recommended; discovering = exSession },
                onMyCoaches: { discoveryMode = .myCoaches; discovering = exSession },
                onSearch: { discoveryMode = .search; discovering = exSession }
            )
        }
    }

    private var emptyWorkout: some View {
        TTEmptyState(symbol: "checkmark.seal", title: "Nothing to train",
                     message: "This workout has no exercises.")
            .frame(maxHeight: .infinity)
    }

    // MARK: Bottom nav

    private var bottomBar: some View {
        HStack(spacing: TTSpace.sm) {
            navButton(system: "chevron.left", label: "Previous", disabled: currentIndex == 0) {
                withAnimation(TTAnim.quick) { currentIndex = max(0, currentIndex - 1) }
            }
            if currentIndex == exercises.count - 1 {
                TTPrimaryButton(title: "Finish", systemImage: "flag.checkered") { showFinishConfirm = true }
            } else {
                navButton(system: "chevron.right", label: "Next", disabled: false, primary: true) {
                    withAnimation(TTAnim.quick) { currentIndex = min(exercises.count - 1, currentIndex + 1) }
                }
            }
        }
        .padding(.horizontal, TTSpace.md)
        .padding(.top, TTSpace.xs)
        .padding(.bottom, TTSpace.xs)
        .background(.ultraThinMaterial)
    }

    private func navButton(system: String, label: String, disabled: Bool, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            TTHaptics.lightTick()
            action()
        }) {
            HStack(spacing: TTSpace.xs) {
                if system == "chevron.left" { Image(systemName: system) }
                Text(label).font(TTFont.headline())
                if system == "chevron.right" { Image(systemName: system) }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(primary ? .white : TTColor.textPrimary)
            .background(primary ? TTColor.brandRed : TTColor.controlFill,
                        in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
        }
        .buttonStyle(TTCardPressStyle())
        .opacity(disabled ? 0.4 : 1)
        .disabled(disabled)
    }

    // MARK: Actions

    private func handleSetCompleted(for exSession: ExerciseSession) {
        guard settings.autoStartRest else { return }
        let rest = exSession.exercise?.effectiveRestSeconds ?? settings.defaultRestSeconds
        if rest > 0 {
            restTimer.start(seconds: rest, playSound: settings.restAlertSound)
        }
    }

    private func attachCoach(_ result: VideoResult, to exercise: Exercise) {
        CoachingLibrary.attach(result, to: exercise, context: context)
        TTHaptics.coachSelected()
    }

    private func removeCoach(from exercise: Exercise) {
        withAnimation(TTAnim.standard) {
            CoachingLibrary.removePrimaryCoach(from: exercise, context: context)
        }
        TTHaptics.lightTick()
    }
}
