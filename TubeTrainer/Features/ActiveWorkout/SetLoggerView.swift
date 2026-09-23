import SwiftUI
import SwiftData
import Charts

/// Last-time summary + fast set logging. Prefilled from previous performance;
/// large thumb targets; +/- steppers and direct keypad entry; instant persistence.
struct SetLoggerView: View {
    @Bindable var exSession: ExerciseSession
    var onSetCompleted: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    private var lastSession: ExerciseSession? {
        guard let exercise = exSession.exercise else { return nil }
        return PerformanceStore.lastSession(for: exercise,
                                             excluding: exSession.workoutSession?.id,
                                             context: context)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TTSpace.md) {
            if let exercise = exSession.exercise {
                LastTimeHistoryCard(exercise: exercise,
                                    currentSessionID: exSession.workoutSession?.id,
                                    unit: settings.weightUnit)
            }

            VStack(spacing: TTSpace.xs) {
                columnHeader
                ForEach(Array(exSession.orderedSets.enumerated()), id: \.element.id) { index, set in
                    SetRow(
                        set: set,
                        previous: lastSession?.orderedSets[safe: index],
                        unit: settings.weightUnit,
                        onComplete: { completeSet(set) },
                        onDelete: exSession.orderedSets.count > 1 ? { deleteSet(set) } : nil
                    )
                }
            }

            Button {
                addSet()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add set").font(TTFont.subheadline().weight(.semibold))
                }
                .foregroundStyle(TTColor.brandRed)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(TTColor.brandRedSoft, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
            }
            .buttonStyle(TTCardPressStyle())
        }
    }

    // MARK: Column header

    private var columnHeader: some View {
        HStack(spacing: TTSpace.xs) {
            Text("SET").frame(width: 24, alignment: .leading)
            Text(settings.weightUnit.label.uppercased()).frame(maxWidth: .infinity)
            Text("REPS").frame(maxWidth: .infinity)
            Spacer().frame(width: 44)
        }
        .font(TTFont.caption())
        .foregroundStyle(TTColor.textTertiary)
        .padding(.horizontal, TTSpace.xs)
    }

    // MARK: Mutations

    private func completeSet(_ set: WorkoutSet) {
        let nowCompleting = !set.isCompleted
        withAnimation(TTAnim.quick) {
            set.completedAt = set.isCompleted ? nil : .now
        }
        try? context.save()
        if nowCompleting {
            TTHaptics.setCompleted()
            onSetCompleted()
        }
    }

    private func addSet() {
        let ordered = exSession.orderedSets
        let next = (ordered.last?.setNumber ?? 0) + 1
        let template = ordered.last
        let set = WorkoutSet(setNumber: next,
                             weight: template?.weight ?? 0,
                             reps: template?.reps ?? 0)
        set.exerciseSession = exSession
        context.insert(set)
        exSession.sets.append(set)
        try? context.save()
        TTHaptics.lightTick()
    }

    private func deleteSet(_ set: WorkoutSet) {
        withAnimation(TTAnim.quick) {
            context.delete(set)
        }
        // Renumber remaining sets.
        for (i, s) in exSession.orderedSets.enumerated() { s.setNumber = i + 1 }
        try? context.save()
    }
}

// MARK: - Last time / progress card

/// The card above the sets. Toggles between the most recent session ("Last time")
/// and a progress chart + recent-session list ("Progress"). History is loaded once
/// via `.task`, so the 1s workout timer re-render never re-runs the fetch.
private struct LastTimeHistoryCard: View {
    let exercise: Exercise
    let currentSessionID: UUID?
    let unit: WeightUnit

    @Environment(\.modelContext) private var context

    private enum Tab: Hashable { case lastTime, progress }
    @State private var tab: Tab = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-progressTab") { return .progress }
        #endif
        return .lastTime
    }()
    @State private var sessions: [ExerciseSession] = []   // newest first

    var body: some View {
        VStack(alignment: .leading, spacing: TTSpace.sm) {
            Picker("", selection: $tab) {
                Text("LAST TIME").tag(Tab.lastTime)
                Text("PROGRESS").tag(Tab.progress)
            }
            .pickerStyle(.segmented)

            switch tab {
            case .lastTime: lastTimeContent
            case .progress: progressContent
            }
        }
        .padding(TTSpace.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
        .task {
            sessions = PerformanceStore.history(for: exercise, limit: 30, context: context)
                .filter { $0.workoutSession?.id != currentSessionID }
        }
    }

    // MARK: Last time

    @ViewBuilder private var lastTimeContent: some View {
        if let last = sessions.first {
            HStack(spacing: TTSpace.sm) {
                ForEach(last.orderedSets.filter { $0.isCompleted }.prefix(5)) { set in
                    Text(TTFormat.weightReps(set.weight, reps: set.reps))
                        .font(TTFont.numeric(15, weight: .semibold))
                        .foregroundStyle(TTColor.textPrimary)
                        .padding(.horizontal, TTSpace.xs)
                        .padding(.vertical, 6)
                        .background(TTColor.controlFill, in: Capsule())
                }
            }
            if let when = last.workoutSession?.startedAt {
                Text(TTFormat.lastTrained(when))
                    .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
            }
        } else {
            Text("No history yet — finish this workout to start tracking.")
                .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
        }
    }

    // MARK: Progress

    private struct TopSet: Identifiable { let id: UUID; let date: Date; let top: Double }

    /// Heaviest completed set per session, oldest → newest for the chart.
    private var topSets: [TopSet] {
        sessions.compactMap { s in
            guard let date = s.workoutSession?.startedAt else { return nil }
            let top = s.orderedSets.filter { $0.isCompleted }.map(\.weight).max() ?? 0
            guard top > 0 else { return nil }
            return TopSet(id: s.id, date: date, top: top)
        }
        .sorted { $0.date < $1.date }
    }

    @ViewBuilder private var progressContent: some View {
        let points = topSets
        if points.count >= 2 {
            Text("Top set (\(unit.label))")
                .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
            Chart(points) { p in
                LineMark(x: .value("Date", p.date), y: .value("Top set", p.top))
                    .foregroundStyle(TTColor.brandRed)
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", p.date), y: .value("Top set", p.top))
                    .foregroundStyle(TTColor.brandRed)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 130)
        } else if points.count == 1 {
            Text("One session so far — a trend appears after your next.")
                .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
        }

        // Recent sessions
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(sessions.prefix(6)), id: \.id) { s in
                if let when = s.workoutSession?.startedAt {
                    HStack(alignment: .firstTextBaseline, spacing: TTSpace.sm) {
                        Text(when.formatted(.dateTime.month(.abbreviated).day()))
                            .font(TTFont.caption())
                            .foregroundStyle(TTColor.textTertiary)
                            .frame(width: 52, alignment: .leading)
                        Text(sessionSummary(s))
                            .font(TTFont.numeric(13, weight: .medium))
                            .foregroundStyle(TTColor.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            if sessions.isEmpty {
                Text("No past sessions yet.")
                    .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
            }
        }
    }

    private func sessionSummary(_ s: ExerciseSession) -> String {
        s.orderedSets.filter { $0.isCompleted }
            .map { TTFormat.weightReps($0.weight, reps: $0.reps) }
            .joined(separator: "  ")
    }
}

// MARK: - Single set row

struct SetRow: View {
    @Bindable var set: WorkoutSet
    let previous: WorkoutSet?
    let unit: WeightUnit
    var onComplete: () -> Void
    var onDelete: (() -> Void)?

    @Environment(\.modelContext) private var context
    @FocusState private var focusedField: Field?

    // Local text state, decoupled from the model. Binding a TextField straight to
    // the SwiftData model lets a re-render (the 1s workout timer) push the field's
    // stale displayed value back through the setter, clobbering stepper changes.
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""

    enum Field { case weight, reps }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: TTSpace.xs) {
                // Set number
                Text("\(set.setNumber)")
                    .font(TTFont.numeric(16, weight: .bold))
                    .foregroundStyle(set.isCompleted ? TTColor.success : TTColor.textSecondary)
                    .frame(width: 24, alignment: .leading)

                // Weight
                valueField(text: $weightInput, field: .weight, step: unit.step)

                // Reps
                valueField(text: $repsInput, field: .reps, step: 1)

                // Complete
                Button(action: onComplete) {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(set.isCompleted ? TTColor.success : TTColor.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(set.isCompleted ? "Mark set \(set.setNumber) incomplete" : "Complete set \(set.setNumber)")
                .accessibilityIdentifier("completeSet")
            }

            // Previous performance — mirrors the columns above: left-aligned "Last time"
            // label, with each number centered under its matching field. Tap to prefill.
            if let previous {
                Button { prefill(from: previous) } label: {
                    HStack(spacing: TTSpace.xs) {
                        Spacer().frame(width: 24)                              // under SET
                        Text(TTFormat.number(previous.weight))
                            .frame(maxWidth: .infinity)                        // under weight field
                        Text("\(previous.reps)")
                            .frame(maxWidth: .infinity)                        // under reps field
                        Spacer().frame(width: 44)                             // under complete
                    }
                    .font(TTFont.caption())
                    .foregroundStyle(TTColor.textTertiary)
                    .lineLimit(1)
                    .overlay(alignment: .leading) {
                        Text("Last time").font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("prevForSet")
            }
        }
        .padding(.horizontal, TTSpace.xs)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous)
                .fill(set.isCompleted ? TTColor.success.opacity(0.10) : TTColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous)
                .strokeBorder(set.isCompleted ? TTColor.success.opacity(0.35) : .clear, lineWidth: 1)
        )
        .swipeActionsIfPossible(onDelete: onDelete)
        .onAppear { syncInputs() }
        .onChange(of: weightInput) { _, newValue in
            let parsed = max(0, Double(newValue.replacingOccurrences(of: ",", with: ".")) ?? 0)
            if parsed != set.weight { set.weight = parsed; save() }
        }
        .onChange(of: repsInput) { _, newValue in
            let parsed = max(0, Int(newValue.filter { $0.isNumber }) ?? 0)
            if parsed != set.reps { set.reps = parsed; save() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField != nil {
                    Button { adjustFocused(-1) } label: { Image(systemName: "minus") }
                    Button { adjustFocused(1) } label: { Image(systemName: "plus") }
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: Value field with keypad + steppers

    private func valueField(text: Binding<String>, field: Field, step: Double) -> some View {
        let key = field == .weight ? "weight" : "reps"
        // Weight needs room for the widest realistic value: 3 digits + decimal, e.g.
        // "102.5" (kg steps in 2.5s). Reps are whole numbers, so 3 digits ("120").
        let fieldMinWidth: CGFloat = field == .weight ? 58 : 40
        return HStack(spacing: 2) {
            stepperButton(icon: "minus", id: "stepper.\(key).minus") { adjust(field, by: -step) }

            TextField("0", text: text)
                .font(TTFont.numeric(16, weight: .semibold))
                .foregroundStyle(TTColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .keyboardType(field == .weight ? .decimalPad : .numberPad)
                .focused($focusedField, equals: field)
                .frame(minWidth: fieldMinWidth, maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: TTRadius.sm)
                        .fill(focusedField == field ? TTColor.controlFillActive : TTColor.controlFill)
                )
                .accessibilityIdentifier("field.\(key)")

            stepperButton(icon: "plus", id: "stepper.\(key).plus") { adjust(field, by: step) }
        }
    }

    /// A stepper button whose *entire* frame is tappable. The previous version used a
    /// bare SF Symbol with no contentShape, so only the drawn glyph took touches —
    /// making "minus" (a hairline) effectively dead and "plus" hard to hit.
    private func stepperButton(icon: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.footnote.weight(.bold))
                .foregroundStyle(TTColor.textSecondary)
                .frame(width: 28, height: 44)
                .background(RoundedRectangle(cornerRadius: TTRadius.sm).fill(TTColor.controlFill))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    // MARK: Bindings

    private static func weightString(_ weight: Double) -> String { weight == 0 ? "" : TTFormat.number(weight) }
    private static func repsString(_ reps: Int) -> String { reps == 0 ? "" : String(reps) }

    /// Refresh the local text fields from the model (on appear and after stepper/prefill writes).
    private func syncInputs() {
        weightInput = Self.weightString(set.weight)
        repsInput = Self.repsString(set.reps)
    }

    private func adjust(_ field: Field, by delta: Double) {
        switch field {
        case .weight:
            set.weight = max(0, ((set.weight + delta) * 100).rounded() / 100)
            weightInput = Self.weightString(set.weight)
        case .reps:
            set.reps = max(0, set.reps + Int(delta))
            repsInput = Self.repsString(set.reps)
        }
        TTHaptics.lightTick()
        save()
    }

    private func adjustFocused(_ direction: Int) {
        guard let focusedField else { return }
        let step: Double = focusedField == .weight ? unit.smallStep : 1
        adjust(focusedField, by: step * Double(direction))
    }

    private func prefill(from previous: WorkoutSet) {
        set.weight = previous.weight
        set.reps = previous.reps
        syncInputs()
        TTHaptics.lightTick()
        save()
    }

    private func save() { try? context.save() }
}

// MARK: - Conditional swipe-to-delete

private extension View {
    @ViewBuilder
    func swipeActionsIfPossible(onDelete: (() -> Void)?) -> some View {
        if let onDelete {
            self.contextMenu {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete set", systemImage: "trash")
                }
            }
        } else {
            self
        }
    }
}
