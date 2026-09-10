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
    @State private var editingWorkouts = false
    @State private var namingWorkout = false
    @State private var newWorkoutName = ""
    @State private var pendingDelete: WorkoutTemplate?
    @State private var pendingReset: TrainingStructure?

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
            .onAppear {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-editWorkouts") { editingWorkouts = true }
                #endif
            }
            .alert("New workout", isPresented: $namingWorkout) {
                TextField("Name (e.g. Monday)", text: $newWorkoutName)
                Button("Cancel", role: .cancel) {}
                Button("Create") { createWorkout() }
            } message: {
                Text("Give it a name — you'll add exercises next.")
            }
            .confirmationDialog("Delete workout?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                presenting: pendingDelete) { template in
                Button("Delete \(template.name)", role: .destructive) { deleteWorkout(template) }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: { _ in
                Text("This removes the workout. Your logged history is kept.")
            }
            .confirmationDialog("Reset your split?",
                isPresented: Binding(get: { pendingReset != nil }, set: { if !$0 { pendingReset = nil } }),
                presenting: pendingReset) { structure in
                Button("Replace with \(structure.title)", role: .destructive) { resetSplit(structure) }
                Button("Cancel", role: .cancel) { pendingReset = nil }
            } message: { structure in
                Text("Removes your current workouts and creates \(structure.title). Your logged history is kept.")
            }
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
            VStack(spacing: TTSpace.sm) {
                TabView(selection: $heroIndex) {
                    ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                        heroCard(template, isNext: template.id == nextTemplate?.id)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: heroHeight)
                .onAppear {
                    if let idx = templates.firstIndex(where: { $0.id == nextTemplate?.id }) {
                        heroIndex = idx
                    }
                }
                heroDots
            }
        }
    }

    /// Custom page indicator, sitting just under the card.
    private var heroDots: some View {
        HStack(spacing: 6) {
            ForEach(templates.indices, id: \.self) { i in
                Capsule()
                    .fill(i == heroIndex ? TTColor.brandRed : TTColor.textTertiary.opacity(0.5))
                    .frame(width: i == heroIndex ? 18 : 6, height: 6)
            }
        }
        .animation(TTAnim.quick, value: heroIndex)
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
                         message: "Create a workout, or start from a ready-made split.")
            VStack(spacing: TTSpace.xs) {
                TTPrimaryButton(title: "New workout", systemImage: "plus") {
                    newWorkoutName = ""; namingWorkout = true
                }
                Menu {
                    Section("Start from a split") {
                        ForEach(TrainingStructure.allCases.filter { $0 != .custom }) { structure in
                            Button(structure.title) { resetSplit(structure) }
                        }
                    }
                } label: {
                    Text("Choose a split")
                        .font(TTFont.headline())
                        .foregroundStyle(TTColor.textPrimary)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(TTColor.controlFill, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
                }
            }
        }
        .ttCard(padding: TTSpace.lg)
    }

    // MARK: All workouts

    @ViewBuilder private var allWorkoutsSection: some View {
        if !templates.isEmpty {
            VStack(alignment: .leading, spacing: TTSpace.sm) {
                TTSectionHeader(title: "Your workouts",
                                actionTitle: editingWorkouts ? "Done" : "Edit") {
                    withAnimation(TTAnim.quick) { editingWorkouts.toggle() }
                }
                ForEach(templates) { template in
                    workoutRow(template)
                }
                if editingWorkouts {
                    workoutEditActions
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

    @ViewBuilder private func workoutRow(_ template: WorkoutTemplate) -> some View {
        if editingWorkouts {
            HStack(spacing: TTSpace.xs) {
                Button { pendingDelete = template } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(TTColor.brandRed)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(template.name)")

                WorkoutSummaryRow(template: template, showDragHandle: true)
                    .opacity(draggingID == template.id ? 0.35 : 1)
            }
            .draggable(template.id.uuidString) {
                WorkoutSummaryRow(template: template, showDragHandle: true)
                    .frame(width: 300).opacity(0.9)
                    .onAppear { draggingID = template.id }
            }
            .dropDestination(for: String.self) { items, _ in
                draggingID = nil
                guard let raw = items.first, let dragged = UUID(uuidString: raw) else { return false }
                return moveWorkout(dragged, onto: template.id)
            }
        } else {
            NavigationLink(value: template) {
                WorkoutSummaryRow(template: template)
            }
            .buttonStyle(TTCardPressStyle())
        }
    }

    private var workoutEditActions: some View {
        VStack(spacing: TTSpace.xs) {
            Button { newWorkoutName = ""; namingWorkout = true } label: {
                editActionLabel("Add a workout day", systemImage: "plus")
            }
            Menu {
                Section("Replace your workouts with a split") {
                    ForEach(TrainingStructure.allCases.filter { $0 != .custom }) { structure in
                        Button(structure.title) { pendingReset = structure }
                    }
                }
            } label: {
                editActionLabel("Reset to a split…", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .padding(.top, 2)
    }

    private func editActionLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: TTSpace.xs) {
            Image(systemName: systemImage)
            Text(title).font(TTFont.subheadline().weight(.semibold))
            Spacer()
        }
        .foregroundStyle(TTColor.brandRed)
        .padding(TTSpace.sm)
        .frame(maxWidth: .infinity)
        .background(TTColor.brandRedSoft, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
    }

    // MARK: Workout create / delete / reset

    private func createWorkout() {
        let name = newWorkoutName.trimmingCharacters(in: .whitespaces)
        let order = (templates.map(\.ordering).max() ?? -1) + 1
        let template = WorkoutTemplate(name: name.isEmpty ? "New Workout" : name, ordering: order)
        context.insert(template)
        try? context.save()
        TTHaptics.lightTick()
        editingWorkouts = false
        path.append(template)   // open the plan to add exercises
    }

    private func deleteWorkout(_ template: WorkoutTemplate) {
        withAnimation(TTAnim.quick) {
            context.delete(template)
            try? context.save()
        }
        pendingDelete = nil
        heroIndex = 0
        TTHaptics.lightTick()
    }

    private func resetSplit(_ structure: TrainingStructure) {
        for template in templates { context.delete(template) }
        CatalogSeeder.buildTemplates(for: structure, in: context)
        try? context.save()
        pendingReset = nil
        editingWorkouts = false
        heroIndex = 0
        TTHaptics.lightTick()
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
    var showDragHandle: Bool = false
    var body: some View {
        HStack(spacing: TTSpace.sm) {
            if showDragHandle {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(TTColor.textTertiary)
                    .accessibilityLabel("Drag to reorder")
            }
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
