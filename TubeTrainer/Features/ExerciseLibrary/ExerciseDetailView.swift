import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Environment(AppSettings.self) private var settings

    @State private var discovering = false
    @State private var discoveryMode: CoachingDiscoveryModel.Mode = .recommended
    @State private var editing = false
    @State private var records = PerformanceStore.Records()
    @State private var history: [ExerciseSession] = []

    var body: some View {
        ZStack {
            TTBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: TTSpace.lg) {
                    coachSection
                    recordsSection
                    trainSection
                    historySection
                }
                .padding(TTSpace.md)
                .padding(.bottom, TTSpace.xxl)
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exercise.isFavorite.toggle()
                    try? context.save()
                    TTHaptics.lightTick()
                } label: {
                    Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(exercise.isFavorite ? TTColor.brandRed : TTColor.textSecondary)
                }
                .accessibilityLabel(exercise.isFavorite ? "Remove from favourites" : "Add to favourites")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Coach controls live on the video (or the Find-a-coach panel).
                    // This menu holds exercise-level settings only.
                    Button { editing = true } label: { Label("Edit exercise", systemImage: "pencil") }
                    restMenu
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $discovering) {
            CoachingDiscoveryView(exercise: exercise, startMode: discoveryMode) { attachCoach($0) }
        }
        .sheet(isPresented: $editing) {
            CustomExerciseEditor(existing: exercise)
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        records = PerformanceStore.records(for: exercise, context: context)
        history = PerformanceStore.history(for: exercise, limit: 20, context: context)
    }

    // MARK: Coach

    @ViewBuilder private var coachSection: some View {
        VStack(alignment: .leading, spacing: TTSpace.sm) {
            TTSectionHeader(title: "Coach")
            if let source = exercise.primaryCoach {
                TTVideoHero(source: source,
                            onChangeCoach: { discovering = true },
                            onRemoveCoach: { removeCoach() })
                if exercise.coachingSources.count > 1 {
                    Text("\(exercise.coachingSources.count) saved videos")
                        .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
                }
            } else {
                TTEmptyCoachView(
                    exerciseName: exercise.name,
                    onRecommended: { discoveryMode = .recommended; discovering = true },
                    onMyCoaches: { discoveryMode = .myCoaches; discovering = true },
                    onSearch: { discoveryMode = .search; discovering = true }
                )
            }
        }
    }

    // MARK: Records

    @ViewBuilder private var recordsSection: some View {
        if records.heaviestWeight > 0 {
            VStack(alignment: .leading, spacing: TTSpace.sm) {
                TTSectionHeader(title: "Personal Records")
                HStack(spacing: TTSpace.sm) {
                    if let set = records.heaviestSet {
                        recordCard("Heaviest", TTFormat.weightReps(set.weight, reps: set.reps), "dumbbell.fill")
                    }
                    if records.bestEstimated1RM > 0 {
                        recordCard("Est. 1RM", TTFormat.weight(records.bestEstimated1RM.rounded(), unit: settings.weightUnit), "chart.line.uptrend.xyaxis")
                    }
                }
                Text("Estimated 1RM uses the Epley formula — a guide, not a medical measure.")
                    .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
            }
        }
    }

    private func recordCard(_ label: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol).foregroundStyle(TTColor.brandRed)
            Text(value).font(TTFont.numeric(19, weight: .bold)).foregroundStyle(TTColor.textPrimary)
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(label).font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TTSpace.md)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous))
    }

    // MARK: Train

    private var trainSection: some View {
        VStack(alignment: .leading, spacing: TTSpace.sm) {
            TTSectionHeader(title: "Train")
            if let last = history.first {
                VStack(alignment: .leading, spacing: TTSpace.xs) {
                    Text("Last time · \(TTFormat.lastTrained(last.workoutSession?.startedAt ?? .now))")
                        .font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
                    setChips(last)
                }
                .padding(TTSpace.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
            }
            TTPrimaryButton(title: "Log this exercise", systemImage: "plus") {
                let session = WorkoutCoordinator.startQuick(exercise: exercise, context: context)
                appState.resume(sessionID: session.id)
            }
        }
    }

    private func setChips(_ session: ExerciseSession) -> some View {
        FlexWrap(spacing: TTSpace.xs) {
            ForEach(session.orderedSets.filter { $0.isCompleted }) { set in
                Text(TTFormat.weightReps(set.weight, reps: set.reps))
                    .font(TTFont.numeric(14, weight: .semibold))
                    .foregroundStyle(TTColor.textPrimary)
                    .padding(.horizontal, TTSpace.xs).padding(.vertical, 6)
                    .background(TTColor.controlFill, in: Capsule())
            }
        }
    }

    // MARK: History

    @ViewBuilder private var historySection: some View {
        if !history.isEmpty {
            VStack(alignment: .leading, spacing: TTSpace.sm) {
                TTSectionHeader(title: "History")
                ForEach(history.prefix(8)) { session in
                    HStack(alignment: .top, spacing: TTSpace.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(TTFormat.mediumDate(session.workoutSession?.startedAt ?? .now))
                                .font(TTFont.subheadline().weight(.semibold))
                                .foregroundStyle(TTColor.textPrimary)
                            setChips(session)
                        }
                        Spacer()
                    }
                    .padding(TTSpace.sm)
                    .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
                }
            }
        } else {
            TTEmptyState(symbol: "clock", title: "No history yet",
                         message: "Your sets for \(exercise.name) will show up here.")
        }
    }

    private var restMenu: some View {
        Menu("Rest timer") {
            Button(exercise.restOverrideSeconds == nil ? "✓ Use default (\(TTFormat.rest(settings.defaultRestSeconds)))" : "Use default") {
                exercise.restOverrideSeconds = nil; try? context.save()
            }
            ForEach(AppSettings.restPresets, id: \.self) { preset in
                Button((exercise.restOverrideSeconds == preset ? "✓ " : "") + TTFormat.rest(preset)) {
                    exercise.restOverrideSeconds = preset; try? context.save()
                }
            }
        }
    }

    private func attachCoach(_ result: VideoResult) {
        CoachingLibrary.attach(result, to: exercise, context: context)
        TTHaptics.coachSelected()
        reload()
    }

    private func removeCoach() {
        withAnimation(TTAnim.standard) {
            CoachingLibrary.removePrimaryCoach(from: exercise, context: context)
        }
        TTHaptics.lightTick()
        reload()
    }
}

// MARK: - Simple flow layout for set chips

struct FlexWrap: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var x: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                totalHeight += rowHeight + spacing
                rows.append([])
                x = 0; rowHeight = 0
            }
            rows[rows.count - 1].append(size)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
