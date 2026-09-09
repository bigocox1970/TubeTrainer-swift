import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @State private var model = OnboardingModel()

    var body: some View {
        ZStack {
            TTBackground()
            VStack(spacing: 0) {
                if model.step > 0 {
                    progressBar
                }
                content
            }
        }
        .animation(TTAnim.standard, value: model.step)
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...model.totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= model.step ? TTColor.brandRed : TTColor.controlFill)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, TTSpace.md)
        .padding(.top, TTSpace.sm)
    }

    @ViewBuilder private var content: some View {
        switch model.step {
        case 0: BrandStep(model: model)
        case 1: ExperienceStep(model: model)
        case 2: StructureStep(model: model)
        case 3: CustomizeStep(model: model)
        case 4: CoachesStep(model: model)
        default: CoachingExplainerStep(model: model) {
            model.finish(context: context, settings: settings)
        }
        }
    }
}

// MARK: - Shared chrome

private struct OnboardingScaffold<Content: View>: View {
    let title: String
    var subtitle: String?
    var primaryTitle: String = "Continue"
    var onPrimary: () -> Void
    var onBack: (() -> Void)?
    var secondary: (title: String, action: () -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: TTSpace.md) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.headline).foregroundStyle(TTColor.textSecondary)
                        .frame(width: 40, height: 40)
                }
            }
            VStack(alignment: .leading, spacing: TTSpace.xs) {
                Text(title).font(TTFont.largeTitle()).foregroundStyle(TTColor.textPrimary)
                if let subtitle {
                    Text(subtitle).font(TTFont.body()).foregroundStyle(TTColor.textSecondary)
                }
            }
            content
            Spacer(minLength: 0)
            VStack(spacing: TTSpace.xs) {
                TTPrimaryButton(title: primaryTitle, action: onPrimary)
                if let secondary {
                    TTTextButton(title: secondary.title, color: TTColor.textSecondary, action: secondary.action)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
        }
        .padding(TTSpace.md)
    }
}

// MARK: - Step 1: Brand

private struct BrandStep: View {
    @Bindable var model: OnboardingModel
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(spacing: TTSpace.lg) {
            Spacer()
            AppIconMark()
            VStack(spacing: TTSpace.sm) {
                Text("Your coaches.\nYour exercises.\nYour progress.")
                    .font(TTFont.largeTitle().weight(.heavy))
                    .foregroundStyle(TTColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Save the best exercise coaching you find on YouTube and keep it right beside your workout.")
                    .font(TTFont.body())
                    .foregroundStyle(TTColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, TTSpace.sm)
            }
            Spacer()
            VStack(spacing: TTSpace.xs) {
                TTPrimaryButton(title: "Build My Trainer") {
                    model.loadPlan()
                    withAnimation(TTAnim.standard) { model.step = 1 }
                }
                TTTextButton(title: "I'll set it up myself", color: TTColor.textSecondary) {
                    model.skipToDefaults(context: context, settings: settings)
                }
                .frame(maxWidth: .infinity).frame(height: 44)
            }
        }
        .padding(TTSpace.md)
    }
}

struct AppIconMark: View {
    var body: some View {
        // A restrained brand mark (play + dumbbell) — not the full app icon splashed on screen.
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(TTColor.brandRed)
                .frame(width: 108, height: 108)
                .shadow(color: TTColor.brandRed.opacity(0.4), radius: 20, y: 8)
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Step 2: Experience

private struct ExperienceStep: View {
    @Bindable var model: OnboardingModel
    var body: some View {
        OnboardingScaffold(
            title: "How much training have you done?",
            subtitle: "This tunes starting suggestions. You can change anything later.",
            onPrimary: { withAnimation(TTAnim.standard) { model.step = 2 } },
            onBack: { withAnimation(TTAnim.standard) { model.step = 0 } }
        ) {
            VStack(spacing: TTSpace.sm) {
                ForEach(ExperienceLevel.allCases) { level in
                    SelectionCard(
                        title: level.title,
                        subtitle: level.blurb,
                        isSelected: model.experience == level
                    ) { model.experience = level }
                }
            }
        }
    }
}

// MARK: - Step 3: Structure

private struct StructureStep: View {
    @Bindable var model: OnboardingModel
    var body: some View {
        OnboardingScaffold(
            title: "Pick a training structure",
            subtitle: "A starting point, not a prescription. Not medical advice.",
            onPrimary: {
                model.loadPlan()
                withAnimation(TTAnim.standard) { model.step = 3 }
            },
            onBack: { withAnimation(TTAnim.standard) { model.step = 1 } }
        ) {
            VStack(spacing: TTSpace.sm) {
                ForEach(TrainingStructure.allCases) { structure in
                    SelectionCard(
                        title: structure.title,
                        subtitle: structure.blurb,
                        symbol: structure.symbol,
                        isSelected: model.structure == structure
                    ) {
                        model.structure = structure
                        model.loadPlan()
                    }
                }
            }
        }
    }
}

// MARK: - Step 4: Customize

private struct CustomizeStep: View {
    @Bindable var model: OnboardingModel
    @Environment(\.modelContext) private var context
    @State private var editingDay: OnboardingModel.DayPlan.ID?
    @State private var pickingForDay: Int?

    var body: some View {
        OnboardingScaffold(
            title: "Customize your exercises",
            subtitle: "Add, remove or reorder. Seeded with sensible basics.",
            onPrimary: { withAnimation(TTAnim.standard) { model.step = 4 } },
            onBack: { withAnimation(TTAnim.standard) { model.step = 2 } }
        ) {
            ScrollView {
                VStack(spacing: TTSpace.md) {
                    ForEach(Array(model.days.enumerated()), id: \.element.id) { dayIndex, day in
                        DayCard(day: day,
                                onRemove: { name in removeExercise(name, from: dayIndex) },
                                onAdd: { pickingForDay = dayIndex })
                    }
                }
            }
            .sheet(item: Binding(get: { pickingForDay.map { PickerTarget(index: $0) } },
                                 set: { pickingForDay = $0?.index })) { target in
                ExercisePickerView(excludedIDs: []) { exercise in
                    addExercise(exercise.name, to: target.index)
                }
            }
        }
    }

    private struct PickerTarget: Identifiable { let index: Int; var id: Int { index } }

    private func addExercise(_ name: String, to dayIndex: Int) {
        guard model.days.indices.contains(dayIndex) else { return }
        if !model.days[dayIndex].exerciseNames.contains(name) {
            model.days[dayIndex].exerciseNames.append(name)
        }
    }
    private func removeExercise(_ name: String, from dayIndex: Int) {
        guard model.days.indices.contains(dayIndex) else { return }
        model.days[dayIndex].exerciseNames.removeAll { $0 == name }
    }
}

private struct DayCard: View {
    let day: OnboardingModel.DayPlan
    var onRemove: (String) -> Void
    var onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TTSpace.sm) {
            Text(day.name).font(TTFont.title3()).foregroundStyle(TTColor.textPrimary)
            ForEach(day.exerciseNames, id: \.self) { name in
                HStack {
                    Text(name).font(TTFont.subheadline()).foregroundStyle(TTColor.textPrimary)
                    Spacer()
                    Button { onRemove(name) } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(TTColor.textTertiary)
                    }
                }
                .padding(.vertical, 6)
            }
            Button(action: onAdd) {
                HStack { Image(systemName: "plus"); Text("Add exercise") }
                    .font(TTFont.subheadline().weight(.semibold)).foregroundStyle(TTColor.brandRed)
            }
        }
        .padding(TTSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous))
    }
}

// MARK: - Step 5: Coaches (optional)

private struct CoachesStep: View {
    @Bindable var model: OnboardingModel
    @Environment(\.modelContext) private var context
    @State private var addingCoach = false

    var body: some View {
        OnboardingScaffold(
            title: "Already have trainers you trust?",
            subtitle: "Add favourite YouTube coaches so their videos get prioritised — or skip and discover as you go.",
            onPrimary: { withAnimation(TTAnim.standard) { model.step = 5 } },
            onBack: { withAnimation(TTAnim.standard) { model.step = 3 } },
            secondary: (title: "Skip for now", action: { withAnimation(TTAnim.standard) { model.step = 5 } })
        ) {
            VStack(spacing: TTSpace.sm) {
                CoachesInlineList()
                Button { addingCoach = true } label: {
                    HStack { Image(systemName: "plus.circle.fill"); Text("Add a coach") }
                        .font(TTFont.headline()).foregroundStyle(TTColor.brandRed)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(TTColor.brandRedSoft, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
                }
            }
        }
        .sheet(isPresented: $addingCoach) { AddCoachView() }
    }
}

private struct CoachesInlineList: View {
    @Query(sort: \Coach.createdAt) private var coaches: [Coach]
    @Environment(\.modelContext) private var context
    var body: some View {
        VStack(spacing: TTSpace.xs) {
            ForEach(coaches) { coach in
                CoachRow(coach: coach, exerciseCount: 0) {
                    context.delete(coach); try? context.save()
                }
            }
        }
    }
}

// MARK: - Step 6: Coaching explainer

private struct CoachingExplainerStep: View {
    @Bindable var model: OnboardingModel
    var onFinish: () -> Void

    var body: some View {
        OnboardingScaffold(
            title: "Coaching, built in",
            subtitle: "Every exercise can hold the one explanation that makes it click for you.",
            primaryTitle: "Enter TubeTrainer",
            onPrimary: onFinish,
            onBack: { withAnimation(TTAnim.standard) { model.step = 4 } }
        ) {
            VStack(alignment: .leading, spacing: TTSpace.md) {
                Text("Shoulder Press").font(TTFont.title2()).foregroundStyle(TTColor.textPrimary)
                TTEmptyCoachView(exerciseName: "Shoulder Press",
                                 onRecommended: {}, onMyCoaches: {}, onSearch: {})
                    .allowsHitTesting(false)
                Text("You can change your chosen coaching video whenever you like.")
                    .font(TTFont.footnote()).foregroundStyle(TTColor.textTertiary)
            }
        }
    }
}

// MARK: - Selection card

private struct SelectionCard: View {
    let title: String
    var subtitle: String?
    var symbol: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            TTHaptics.lightTick()
            action()
        } label: {
            HStack(spacing: TTSpace.sm) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.title3).foregroundStyle(isSelected ? .white : TTColor.brandRed)
                        .frame(width: 44, height: 44)
                        .background(isSelected ? TTColor.brandRed : TTColor.brandRedSoft, in: RoundedRectangle(cornerRadius: TTRadius.sm))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(TTFont.headline()).foregroundStyle(TTColor.textPrimary)
                    if let subtitle {
                        Text(subtitle).font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? TTColor.brandRed : TTColor.textTertiary)
            }
            .padding(TTSpace.md)
            .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous)
                    .strokeBorder(isSelected ? TTColor.brandRed : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(TTCardPressStyle())
    }
}
