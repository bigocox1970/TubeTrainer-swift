import SwiftUI
import SwiftData

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
            lastTimeSection

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

    // MARK: Last time

    @ViewBuilder private var lastTimeSection: some View {
        if let last = lastSession, !last.orderedSets.isEmpty {
            VStack(alignment: .leading, spacing: TTSpace.xs) {
                Text("LAST TIME")
                    .font(TTFont.caption()).tracking(1.2)
                    .foregroundStyle(TTColor.textSecondary)
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
            }
            .padding(TTSpace.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
        }
    }

    // MARK: Column header

    private var columnHeader: some View {
        HStack(spacing: TTSpace.xs) {
            Text("SET").frame(width: 34, alignment: .leading)
            Text("PREV").frame(width: 66, alignment: .leading)
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

// MARK: - Single set row

struct SetRow: View {
    @Bindable var set: WorkoutSet
    let previous: WorkoutSet?
    let unit: WeightUnit
    var onComplete: () -> Void
    var onDelete: (() -> Void)?

    @Environment(\.modelContext) private var context
    @FocusState private var focusedField: Field?

    enum Field { case weight, reps }

    var body: some View {
        HStack(spacing: TTSpace.xs) {
            // Set number
            Text("\(set.setNumber)")
                .font(TTFont.numeric(16, weight: .bold))
                .foregroundStyle(set.isCompleted ? TTColor.success : TTColor.textSecondary)
                .frame(width: 34, alignment: .leading)

            // Previous
            Group {
                if let previous {
                    Text(TTFormat.weightReps(previous.weight, reps: previous.reps))
                        .foregroundStyle(TTColor.textTertiary)
                } else {
                    Text("—").foregroundStyle(TTColor.textTertiary)
                }
            }
            .font(TTFont.caption())
            .frame(width: 66, alignment: .leading)
            .onTapGesture { if let previous { prefill(from: previous) } }

            // Weight
            valueField(text: weightText, field: .weight, step: unit.step)

            // Reps
            valueField(text: repsText, field: .reps, step: 1)

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
        HStack(spacing: 2) {
            Button {
                adjust(field, by: -step)
            } label: {
                Image(systemName: "minus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TTColor.textSecondary)
                    .frame(width: 26, height: 40)
            }
            .buttonStyle(.plain)

            TextField("0", text: text)
                .font(TTFont.numeric(19, weight: .semibold))
                .foregroundStyle(TTColor.textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(field == .weight ? .decimalPad : .numberPad)
                .focused($focusedField, equals: field)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: TTRadius.sm)
                        .fill(focusedField == field ? TTColor.controlFillActive : TTColor.controlFill)
                )

            Button {
                adjust(field, by: step)
            } label: {
                Image(systemName: "plus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TTColor.textSecondary)
                    .frame(width: 26, height: 40)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Bindings

    private var weightText: Binding<String> {
        Binding(
            get: { set.weight == 0 ? "" : TTFormat.number(set.weight) },
            set: { newValue in
                set.weight = max(0, Double(newValue.replacingOccurrences(of: ",", with: ".")) ?? 0)
                save()
            }
        )
    }

    private var repsText: Binding<String> {
        Binding(
            get: { set.reps == 0 ? "" : String(set.reps) },
            set: { newValue in
                set.reps = max(0, Int(newValue.filter { $0.isNumber }) ?? 0)
                save()
            }
        )
    }

    private func adjust(_ field: Field, by delta: Double) {
        switch field {
        case .weight: set.weight = max(0, (set.weight + delta * 100).rounded() / 100)
        case .reps: set.reps = max(0, set.reps + Int(delta))
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
