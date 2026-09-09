import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var query = ""
    @State private var filter: LibraryFilter = .all
    @State private var creatingCustom = false

    enum LibraryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case needsCoach = "Needs Coach"
        case hasCoach = "Has Coach"
        var id: String { rawValue }
    }

    private var filtered: [Exercise] {
        exercises
            .filter { ExerciseSearch.matches(query: query, exercise: $0) }
            .filter { ex in
                switch filter {
                case .all: return true
                case .needsCoach: return !ex.hasCoach
                case .hasCoach: return ex.hasCoach
                }
            }
    }

    private var coachedCount: Int { exercises.filter { $0.hasCoach }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                TTBackground()
                VStack(spacing: TTSpace.sm) {
                    TTSearchField(text: $query, placeholder: "Search your exercises")
                        .padding(.horizontal, TTSpace.md)

                    filterBar

                    ScrollView {
                        LazyVStack(spacing: TTSpace.sm) {
                            if filter == .all && query.isEmpty {
                                coachingProgress
                            }
                            ForEach(filtered) { exercise in
                                NavigationLink(value: exercise) {
                                    TTExerciseRow(exercise: exercise, lastPerformance: lastPerf(exercise))
                                }
                                .buttonStyle(TTCardPressStyle())
                            }
                            if filtered.isEmpty {
                                emptyState
                            }
                        }
                        .padding(.horizontal, TTSpace.md)
                        .padding(.bottom, TTSpace.xxl)
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { creatingCustom = true } label: {
                        Image(systemName: "plus")
                    }
                    .foregroundStyle(TTColor.brandRed)
                    .accessibilityLabel("Create exercise")
                }
            }
            .navigationDestination(for: Exercise.self) { ExerciseDetailView(exercise: $0) }
            .sheet(isPresented: $creatingCustom) {
                CustomExerciseEditor()
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TTSpace.xs) {
                ForEach(LibraryFilter.allCases) { f in
                    TTFilterChip(title: f.rawValue, isSelected: filter == f) {
                        withAnimation(TTAnim.quick) { filter = f }
                    }
                }
            }
            .padding(.horizontal, TTSpace.md)
        }
    }

    private var coachingProgress: some View {
        VStack(alignment: .leading, spacing: TTSpace.xs) {
            HStack {
                Text("Your coaching library")
                    .font(TTFont.subheadline().weight(.semibold))
                    .foregroundStyle(TTColor.textPrimary)
                Spacer()
                Text("\(coachedCount) / \(exercises.count)")
                    .font(TTFont.numeric(15, weight: .semibold))
                    .foregroundStyle(TTColor.brandRed)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(TTColor.controlFill)
                    Capsule().fill(TTColor.brandRed)
                        .frame(width: geo.size.width * progressFraction)
                }
            }
            .frame(height: 8)
            Text("Attach a coach whenever a video makes an exercise click.")
                .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
        }
        .padding(TTSpace.md)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous))
        .padding(.bottom, TTSpace.xs)
    }

    private var progressFraction: CGFloat {
        exercises.isEmpty ? 0 : CGFloat(coachedCount) / CGFloat(exercises.count)
    }

    private var emptyState: some View {
        TTEmptyState(
            symbol: filter == .needsCoach ? "checkmark.circle" : "magnifyingglass",
            title: filter == .needsCoach ? "Every exercise has a coach" : "Nothing matches",
            message: filter == .needsCoach ? "Your whole library is coached. Nice work." : "Try different words, or create a custom exercise."
        )
    }

    private func lastPerf(_ exercise: Exercise) -> String? {
        guard let last = PerformanceStore.lastSession(for: exercise, context: context),
              let topSet = last.orderedSets.filter({ $0.isCompleted }).max(by: { $0.weight < $1.weight })
        else { return nil }
        return TTFormat.weightReps(topSet.weight, reps: topSet.reps)
    }
}
