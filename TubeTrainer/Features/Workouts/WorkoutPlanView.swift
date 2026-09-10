import SwiftUI
import SwiftData

struct WorkoutPlanView: View {
    @Bindable var template: WorkoutTemplate
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context

    @State private var isEditing = false
    @State private var showingAddExercise = false
    @State private var renaming = false
    @State private var draftName = ""

    var body: some View {
        ZStack {
            TTBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: TTSpace.md) {
                    headerCard
                    exerciseList
                    if isEditing {
                        TTSecondaryButton(title: "Add exercise", systemImage: "plus") {
                            showingAddExercise = true
                        }
                    }
                }
                .padding(TTSpace.md)
                .padding(.bottom, 120)
            }

            VStack {
                Spacer()
                startBar
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // A brand-new (empty) workout opens ready to name + add exercises.
            if template.orderedExercises.isEmpty { isEditing = true }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation(TTAnim.quick) { isEditing.toggle() }
                }
                .foregroundStyle(TTColor.brandRed)
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .alert("Rename workout", isPresented: $renaming) {
            TextField("Workout name", text: $draftName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = draftName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { template.name = trimmed; try? context.save() }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: TTSpace.xs) {
            HStack {
                Text(template.name)
                    .font(TTFont.largeTitle())
                    .foregroundStyle(TTColor.textPrimary)
                if isEditing {
                    Button {
                        draftName = template.name
                        renaming = true
                    } label: {
                        Image(systemName: "pencil").foregroundStyle(TTColor.brandRed)
                    }
                }
                Spacer()
            }
            Text("\(template.exercises.count) exercises")
                .font(TTFont.subheadline())
                .foregroundStyle(TTColor.textSecondary)
        }
    }

    @ViewBuilder private var exerciseList: some View {
        if template.orderedExercises.isEmpty {
            TTEmptyState(symbol: "dumbbell", title: "No exercises yet",
                         message: "Add the movements you want in this workout.")
                .ttCard()
        } else if isEditing {
            // Editable list with reorder + delete.
            List {
                ForEach(template.orderedExercises) { tie in
                    PlanExerciseEditRow(tie: tie)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(height: CGFloat(template.orderedExercises.count) * 84 + 20)
            .environment(\.editMode, .constant(.active))
        } else {
            VStack(spacing: TTSpace.sm) {
                ForEach(Array(template.orderedExercises.enumerated()), id: \.element.id) { index, tie in
                    PlanExerciseRow(index: index + 1, tie: tie)
                }
            }
        }
    }

    private var startBar: some View {
        TTPrimaryButton(title: "Start Workout", systemImage: "play.fill") {
            let session = WorkoutCoordinator.start(from: template, context: context)
            appState.resume(sessionID: session.id)
        }
        .padding(.horizontal, TTSpace.md)
        .padding(.top, TTSpace.sm)
        .padding(.bottom, TTSpace.xs)
        .background(
            LinearGradient(colors: [TTColor.backgroundPrimary.opacity(0), TTColor.backgroundPrimary],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .disabled(template.orderedExercises.isEmpty)
    }

    // MARK: Mutations

    private func addExercise(_ exercise: Exercise) {
        let order = (template.orderedExercises.last?.order ?? -1) + 1
        let tie = WorkoutTemplateExercise(exercise: exercise, order: order)
        tie.template = template
        context.insert(tie)
        template.exercises.append(tie)
        try? context.save()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = template.orderedExercises
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, tie) in ordered.enumerated() { tie.order = i }
        TTHaptics.reorderSnap()
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        let ordered = template.orderedExercises
        for index in offsets { context.delete(ordered[index]) }
        try? context.save()
    }
}

// MARK: - Rows

struct PlanExerciseRow: View {
    let index: Int
    let tie: WorkoutTemplateExercise
    @Environment(\.modelContext) private var context

    private var lastPerformance: String? {
        guard let exercise = tie.exercise,
              let last = PerformanceStore.lastSession(for: exercise, context: context),
              let topSet = last.orderedSets.filter({ $0.isCompleted }).max(by: { $0.weight < $1.weight })
        else { return nil }
        return "Last: \(TTFormat.weightReps(topSet.weight, reps: topSet.reps))"
    }

    var body: some View {
        if let exercise = tie.exercise {
            NavigationLink(value: exercise) {
                HStack(spacing: TTSpace.sm) {
                    Text("\(index)")
                        .font(TTFont.numeric(17))
                        .foregroundStyle(TTColor.textTertiary)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name).font(TTFont.headline()).foregroundStyle(TTColor.textPrimary)
                        HStack(spacing: TTSpace.xs) {
                            if let target = tie.targetSummary {
                                Text(target).font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
                            }
                            if let lastPerformance {
                                Text("·").foregroundStyle(TTColor.textTertiary)
                                Text(lastPerformance).font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
                            }
                        }
                    }
                    Spacer(minLength: TTSpace.xs)
                    exercise.coachingBadge
                }
                .padding(TTSpace.sm)
                .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
            }
            .buttonStyle(TTCardPressStyle())
        }
    }
}

struct PlanExerciseEditRow: View {
    @Bindable var tie: WorkoutTemplateExercise
    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(spacing: TTSpace.sm) {
            VStack(alignment: .leading, spacing: 6) {
                Text(tie.exercise?.name ?? "Exercise")
                    .font(TTFont.headline()).foregroundStyle(TTColor.textPrimary)
                HStack(spacing: TTSpace.xs) {
                    Stepper(value: Binding(
                        get: { tie.targetSets ?? 3 },
                        set: { tie.targetSets = $0; try? context.save() }
                    ), in: 1...10) {
                        Text("\(tie.targetSets ?? 3) sets")
                            .font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
                    }
                    .fixedSize()
                }
            }
            Spacer()
        }
        .padding(TTSpace.sm)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
    }
}
