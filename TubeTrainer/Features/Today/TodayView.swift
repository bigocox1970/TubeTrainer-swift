import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutTemplate.ordering) private var templates: [WorkoutTemplate]
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt == nil },
           sort: \WorkoutSession.startedAt, order: .reverse) private var inProgress: [WorkoutSession]

    @State private var path = NavigationPath()
    @State private var heroIndex = 0
    @State private var draggingID: UUID?

    private let heroHeight: CGFloat = 262

    private var nextTemplate: WorkoutTemplate? {
        // The least-recently-trained template feels like the natural "next".
        templates.min { a, b in
            (a.lastTrainedAt ?? .distantPast) < (b.lastTrainedAt ?? .distantPast)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                TTBackground()
                VStack(spacing: 0) {
                    TTMainHeader(title: greeting)
                    ScrollView {
                        VStack(alignment: .leading, spacing: TTSpace.lg) {
                            if let session = inProgress.first {
                                continueCard(session)
                            }
                            heroSection
                            allWorkoutsSection
                            recentCoachingSection
                        }
                        .padding(.horizontal, TTSpace.md)
                        .padding(.top, TTSpace.xs)
                        .padding(.bottom, TTSpace.xxl)
                    }
                }
            }
            .navigationDestination(for: WorkoutTemplate.self) { WorkoutPlanView(template: $0) }
            .navigationDestination(for: Exercise.self) { ExerciseDetailView(exercise: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var greeting: String {
        let name = settings.nickname.trimmingCharacters(in: .whitespaces)
        // With a name: keep the prefix tiny so long names still fit.
        if !name.isEmpty { return "Hey \(name)" }
        // No name: room for the full time-of-day greeting.
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good evening"
        }
    }

    // MARK: Continue in-progress

    private func continueCard(_ session: WorkoutSession) -> some View {
        Button {
            appState.resume(sessionID: session.id)
        } label: {
            HStack(spacing: TTSpace.sm) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2).foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(TTColor.brandRed.opacity(0.35), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue workout").font(TTFont.headline()).foregroundStyle(.white)
                    Text("\(session.nameSnapshot) · \(session.completedSetCount) sets logged")
                        .font(TTFont.caption()).foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "play.fill").foregroundStyle(.white)
            }
            .padding(TTSpace.md)
            .background(
                LinearGradient(colors: [TTColor.brandRed, TTColor.brandRedPressed],
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous)
            )
        }
        .buttonStyle(TTCardPressStyle())
    }

    // MARK: Hero — next workout (swipe through all workouts)

    @ViewBuilder private var heroSection: some View {
        if templates.isEmpty {
            noPlansCard
        } else if templates.count == 1 {
            heroCard(templates[0], isNext: true).frame(height: heroHeight)
        } else {
            TabView(selection: $heroIndex) {
                ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                    heroCard(template, isNext: template.id == nextTemplate?.id)
                        .padding(.bottom, 26)   // room for the page dots
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: heroHeight + 26)
            .onAppear {
                if let idx = templates.firstIndex(where: { $0.id == nextTemplate?.id }) {
                    heroIndex = idx
                }
            }
        }
    }

    private func heroCard(_ template: WorkoutTemplate, isNext: Bool) -> some View {
        VStack(alignment: .leading, spacing: TTSpace.md) {
            VStack(alignment: .leading, spacing: TTSpace.xs) {
                Text(isNext ? "NEXT WORKOUT" : "WORKOUT")
                    .font(TTFont.caption()).tracking(1.4)
                    .foregroundStyle(TTColor.brandRed)
                Text(template.name.uppercased())
                    .font(TTFont.hero())
                    .foregroundStyle(TTColor.textPrimary)
                    .lineLimit(2).minimumScaleFactor(0.6)
                HStack(spacing: TTSpace.xs) {
                    Label("\(template.exercises.count) exercises", systemImage: "list.bullet")
                    if let last = template.lastTrainedAt {
                        Text("·").foregroundStyle(TTColor.textTertiary)
                        Text("Last \(TTFormat.lastTrained(last).lowercased())")
                    }
                }
                .font(TTFont.subheadline())
                .foregroundStyle(TTColor.textSecondary)
            }

            Spacer(minLength: TTSpace.xs)

            HStack(spacing: TTSpace.md) {
                NavigationLink(value: template) {
                    Text("View plan")
                        .font(TTFont.subheadline().weight(.semibold))
                        .foregroundStyle(TTColor.textPrimary)
                }
                Spacer()
            }

            TTPrimaryButton(title: "Start Workout", systemImage: "play.fill") {
                startWorkout(template)
            }
        }
        .padding(TTSpace.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: TTRadius.xl, style: .continuous)
                .fill(TTColor.surface)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: template.symbolGuess)
                        .font(.system(size: 120))
                        .foregroundStyle(TTColor.textPrimary.opacity(0.04))
                        .offset(x: 20, y: -10)
                        .clipped()
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: TTRadius.xl, style: .continuous))
    }

    private var noPlansCard: some View {
        VStack(spacing: TTSpace.md) {
            TTEmptyState(symbol: "plus.rectangle.on.folder",
                         title: "Your first session starts here",
                         message: "Create a workout and start training. No account, no setup.")
            TTPrimaryButton(title: "Build a workout", systemImage: "plus") {
                appState.selectedTab = .library
            }
        }
        .ttCard(padding: TTSpace.lg)
    }

    // MARK: All workouts

    @ViewBuilder private var allWorkoutsSection: some View {
        if templates.count > 1 {
            VStack(alignment: .leading, spacing: TTSpace.sm) {
                TTSectionHeader(title: "Your workouts")
                ForEach(templates) { template in
                    NavigationLink(value: template) {
                        WorkoutSummaryRow(template: template)
                            .opacity(draggingID == template.id ? 0.35 : 1)
                    }
                    .buttonStyle(TTCardPressStyle())
                    .draggable(template.id.uuidString) {
                        // Long-press lifts the card to reorder.
                        WorkoutSummaryRow(template: template)
                            .frame(width: 320)
                            .opacity(0.9)
                            .onAppear { draggingID = template.id }
                    }
                    .dropDestination(for: String.self) { items, _ in
                        draggingID = nil
                        guard let raw = items.first, let dragged = UUID(uuidString: raw) else { return false }
                        return moveWorkout(dragged, onto: template.id)
                    }
                }
            }
        }
    }

    /// Reorder templates by rewriting their `ordering`, then persist.
    private func moveWorkout(_ draggedID: UUID, onto targetID: UUID) -> Bool {
        guard draggedID != targetID,
              let from = templates.firstIndex(where: { $0.id == draggedID }),
              let to = templates.firstIndex(where: { $0.id == targetID }) else { return false }
        var ordered = templates
        let moved = ordered.remove(at: from)
        ordered.insert(moved, at: to)
        for (i, template) in ordered.enumerated() { template.ordering = i }
        try? context.save()
        TTHaptics.reorderSnap()
        return true
    }

    // MARK: Recent coaching

    @ViewBuilder private var recentCoachingSection: some View {
        let recent = recentlyCoached
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: TTSpace.sm) {
                TTSectionHeader(title: "Recent coaching")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: TTSpace.sm) {
                        ForEach(recent) { exercise in
                            NavigationLink(value: exercise) {
                                RecentCoachingCard(exercise: exercise)
                            }
                            .buttonStyle(TTCardPressStyle())
                        }
                    }
                }
            }
        }
    }

    private var recentlyCoached: [Exercise] {
        let all = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        return all
            .filter { $0.hasCoach }
            .sorted { ($0.primaryCoach?.createdAt ?? .distantPast) > ($1.primaryCoach?.createdAt ?? .distantPast) }
            .prefix(6)
            .map { $0 }
    }

    private func startWorkout(_ template: WorkoutTemplate) {
        let session = WorkoutCoordinator.start(from: template, context: context)
        appState.resume(sessionID: session.id)
    }
}

// MARK: - Supporting rows

struct WorkoutSummaryRow: View {
    let template: WorkoutTemplate
    var body: some View {
        HStack(spacing: TTSpace.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: TTRadius.sm, style: .continuous).fill(TTColor.controlFill)
                Image(systemName: template.symbolGuess)
                    .foregroundStyle(TTColor.textSecondary)
            }
            .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name).font(TTFont.headline()).foregroundStyle(TTColor.textPrimary)
                Text("\(template.exercises.count) exercises")
                    .font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                .foregroundStyle(TTColor.textTertiary)
        }
        .padding(TTSpace.sm)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
    }
}

struct RecentCoachingCard: View {
    let exercise: Exercise
    var body: some View {
        VStack(alignment: .leading, spacing: TTSpace.xs) {
            TTThumbnail(urlString: exercise.primaryCoach?.thumbnailURL,
                        contentType: exercise.primaryCoach?.contentType ?? .video)
                .frame(width: 200, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
            Text(exercise.name).font(TTFont.subheadline().weight(.semibold))
                .foregroundStyle(TTColor.textPrimary).lineLimit(1)
            Text(exercise.primaryCoach?.channelName ?? "")
                .font(TTFont.caption()).foregroundStyle(TTColor.textSecondary).lineLimit(1)
        }
        .frame(width: 200)
    }
}

extension WorkoutTemplate {
    /// Best-guess glyph from the workout name for subtle decoration.
    var symbolGuess: String {
        let n = name.lowercased()
        if n.contains("push") { return "figure.strengthtraining.traditional" }
        if n.contains("pull") { return "figure.rower" }
        if n.contains("leg") || n.contains("lower") { return "figure.strengthtraining.functional" }
        if n.contains("upper") { return "figure.arms.open" }
        if n.contains("chest") { return "figure.strengthtraining.traditional" }
        if n.contains("back") { return "figure.rower" }
        if n.contains("shoulder") { return "figure.arms.open" }
        if n.contains("arm") { return "dumbbell.fill" }
        return "figure.mixed.cardio"
    }
}
