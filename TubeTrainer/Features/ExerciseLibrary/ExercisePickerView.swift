import SwiftUI
import SwiftData

/// Forgiving searchable exercise picker with an inline "create custom" path.
struct ExercisePickerView: View {
    var excludedIDs: Set<UUID> = []
    var onPick: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var query = ""
    @State private var creatingCustom = false

    private var filtered: [Exercise] {
        allExercises
            .filter { !excludedIDs.contains($0.id) }
            .filter { ExerciseSearch.matches(query: query, exercise: $0) }
    }

    private var grouped: [(MuscleCategory, [Exercise])] {
        Dictionary(grouping: filtered, by: { $0.category })
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TTBackground()
                VStack(spacing: TTSpace.sm) {
                    TTSearchField(text: $query, placeholder: "Search exercises")
                        .padding(.horizontal, TTSpace.md)
                        .padding(.top, TTSpace.xs)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: TTSpace.md, pinnedViews: [.sectionHeaders]) {
                            if !query.isEmpty {
                                createCustomRow
                            }
                            ForEach(grouped, id: \.0) { category, exercises in
                                Section {
                                    VStack(spacing: TTSpace.xs) {
                                        ForEach(exercises) { exercise in
                                            Button {
                                                TTHaptics.lightTick()
                                                onPick(exercise)
                                                dismiss()
                                            } label: {
                                                pickRow(exercise)
                                            }
                                            .buttonStyle(TTCardPressStyle())
                                        }
                                    }
                                } header: {
                                    TTSectionHeader(title: category.rawValue)
                                        .padding(.vertical, 4)
                                        .background(TTColor.backgroundPrimary.opacity(0.95))
                                }
                            }
                            if filtered.isEmpty && query.isEmpty {
                                TTEmptyState(symbol: "magnifyingglass", title: "No exercises",
                                             message: "Your catalog looks empty.")
                            }
                        }
                        .padding(.horizontal, TTSpace.md)
                        .padding(.bottom, TTSpace.xxl)
                    }
                }
            }
            .navigationTitle("Add exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundStyle(TTColor.textSecondary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { creatingCustom = true } label: { Image(systemName: "plus") }
                        .foregroundStyle(TTColor.brandRed)
                }
            }
            .sheet(isPresented: $creatingCustom) {
                CustomExerciseEditor(initialName: query) { newExercise in
                    onPick(newExercise)
                    dismiss()
                }
            }
        }
    }

    private var createCustomRow: some View {
        Button {
            creatingCustom = true
        } label: {
            HStack(spacing: TTSpace.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2).foregroundStyle(TTColor.brandRed)
                Text("Create \"\(query)\"")
                    .font(TTFont.headline()).foregroundStyle(TTColor.textPrimary)
                Spacer()
            }
            .padding(TTSpace.sm)
            .background(TTColor.brandRedSoft, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
        }
        .buttonStyle(TTCardPressStyle())
    }

    private func pickRow(_ exercise: Exercise) -> some View {
        HStack(spacing: TTSpace.sm) {
            Image(systemName: exercise.category.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(TTColor.textSecondary)
                .frame(width: 36, height: 36)
                .background(TTColor.controlFill, in: RoundedRectangle(cornerRadius: TTRadius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name).font(TTFont.subheadline().weight(.semibold))
                    .foregroundStyle(TTColor.textPrimary)
                Text(exercise.equipment.rawValue)
                    .font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
            }
            Spacer()
            if exercise.isCustom {
                TTBadge(text: "Custom", style: .neutral)
            }
            Image(systemName: "plus")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TTColor.brandRed)
        }
        .padding(TTSpace.sm)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
    }
}

// MARK: - Custom exercise editor

struct CustomExerciseEditor: View {
    var initialName: String = ""
    var existing: Exercise?
    var onSave: (Exercise) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name: String
    @State private var category: MuscleCategory
    @State private var equipment: Equipment
    @State private var aliases: String

    init(initialName: String = "", existing: Exercise? = nil, onSave: @escaping (Exercise) -> Void = { _ in }) {
        self.initialName = initialName
        self.existing = existing
        self.onSave = onSave
        _name = State(initialValue: existing?.name ?? initialName)
        _category = State(initialValue: existing?.category ?? .chest)
        _equipment = State(initialValue: existing?.equipment ?? .barbell)
        _aliases = State(initialValue: existing?.aliases.joined(separator: ", ") ?? "")
    }

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                TTBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: TTSpace.md) {
                        field("Name") {
                            TextField("Exercise name", text: $name)
                                .font(TTFont.body()).foregroundStyle(TTColor.textPrimary)
                        }
                        pickerCard("Muscle group", selection: $category, options: MuscleCategory.allCases) { $0.rawValue }
                        pickerCard("Equipment", selection: $equipment, options: Equipment.allCases) { $0.rawValue }
                        field("Also known as (optional)") {
                            TextField("e.g. RDL, stiff-leg", text: $aliases)
                                .font(TTFont.body()).foregroundStyle(TTColor.textPrimary)
                                .autocorrectionDisabled()
                        }
                        Text("Aliases make search forgiving — type any of them to find this exercise.")
                            .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
                    }
                    .padding(TTSpace.md)
                }
            }
            .navigationTitle(existing == nil ? "New exercise" : "Edit exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(TTColor.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .foregroundStyle(canSave ? TTColor.brandRed : TTColor.textTertiary)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: TTSpace.xs) {
            Text(label.uppercased()).font(TTFont.caption()).tracking(1)
                .foregroundStyle(TTColor.textSecondary)
            content()
                .padding(TTSpace.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
        }
    }

    private func pickerCard<T: Hashable & Identifiable>(_ label: String, selection: Binding<T>, options: [T], title: @escaping (T) -> String) -> some View {
        field(label) {
            Menu {
                ForEach(options) { option in
                    Button(title(option)) { selection.wrappedValue = option }
                }
            } label: {
                HStack {
                    Text(title(selection.wrappedValue))
                        .foregroundStyle(TTColor.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption).foregroundStyle(TTColor.textSecondary)
                }
            }
        }
    }

    private func save() {
        let aliasList = aliases.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if let existing {
            existing.name = name
            existing.normalizedName = name.ttNormalized
            existing.category = category
            existing.equipment = equipment
            existing.aliases = aliasList
            try? context.save()
            onSave(existing)
        } else {
            let exercise = Exercise(name: name, category: category, equipment: equipment,
                                    aliases: aliasList, isCustom: true,
                                    defaultRestSeconds: AppSettings.shared.defaultRestSeconds)
            context.insert(exercise)
            try? context.save()
            onSave(exercise)
        }
        TTHaptics.lightTick()
        dismiss()
    }
}
