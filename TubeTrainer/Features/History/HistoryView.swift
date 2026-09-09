import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
           sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            ZStack {
                TTBackground()
                if sessions.isEmpty {
                    TTEmptyState(symbol: "clock.arrow.circlepath",
                                 title: "Your first session starts here",
                                 message: "Finished workouts show up here with volume, sets and records.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: TTSpace.sm) {
                            summaryHeader
                            ForEach(groupedByMonth, id: \.0) { month, monthSessions in
                                Section {
                                    ForEach(monthSessions) { session in
                                        NavigationLink(value: session) {
                                            SessionHistoryRow(session: session, unit: settings.weightUnit)
                                        }
                                        .buttonStyle(TTCardPressStyle())
                                    }
                                } header: {
                                    TTSectionHeader(title: month)
                                        .padding(.top, TTSpace.xs)
                                }
                            }
                        }
                        .padding(TTSpace.md)
                        .padding(.bottom, TTSpace.xxl)
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: WorkoutSession.self) { SessionDetailView(session: $0) }
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: TTSpace.sm) {
            statTile("\(sessions.count)", "Workouts")
            statTile("\(totalSets)", "Sets")
            statTile(streakText, "This week")
        }
        .padding(.bottom, TTSpace.xs)
    }

    private var totalSets: Int {
        sessions.reduce(0) { $0 + $1.completedSetCount }
    }

    private var streakText: String {
        let cal = Calendar.current
        let count = sessions.filter {
            cal.isDate($0.startedAt, equalTo: .now, toGranularity: .weekOfYear)
        }.count
        return "\(count)"
    }

    private func statTile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(TTFont.numeric(22, weight: .bold)).foregroundStyle(TTColor.textPrimary)
            Text(label).font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TTSpace.md)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous))
    }

    private var groupedByMonth: [(String, [WorkoutSession])] {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        let groups = Dictionary(grouping: sessions) { f.string(from: $0.startedAt) }
        return groups.sorted { a, b in
            (a.value.first?.startedAt ?? .distantPast) > (b.value.first?.startedAt ?? .distantPast)
        }
    }
}

struct SessionHistoryRow: View {
    let session: WorkoutSession
    let unit: WeightUnit

    private var volume: Double {
        session.orderedExercises.reduce(0) { acc, ex in
            acc + ex.orderedSets.filter { $0.isCompleted }.reduce(0) { $0 + $1.volume }
        }
    }

    var body: some View {
        HStack(spacing: TTSpace.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: TTRadius.sm, style: .continuous).fill(TTColor.brandRedSoft)
                Text(dayNumber).font(TTFont.numeric(18, weight: .bold)).foregroundStyle(TTColor.brandRed)
            }
            .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.nameSnapshot).font(TTFont.headline()).foregroundStyle(TTColor.textPrimary)
                Text("\(session.orderedExercises.count) exercises · \(session.completedSetCount) sets · \(TTFormat.duration(session.durationSeconds))")
                    .font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(TTColor.textTertiary)
        }
        .padding(TTSpace.sm)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
    }

    private var dayNumber: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: session.startedAt)
    }
}

// MARK: - Session detail

struct SessionDetailView: View {
    let session: WorkoutSession
    @Environment(AppSettings.self) private var settings

    var body: some View {
        ZStack {
            TTBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: TTSpace.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(TTFormat.dayAndTime(session.startedAt))
                            .font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)
                        Text("\(session.completedSetCount) sets · \(TTFormat.duration(session.durationSeconds))")
                            .font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)
                    }
                    ForEach(session.orderedExercises) { ex in
                        VStack(alignment: .leading, spacing: TTSpace.xs) {
                            Text(ex.displayName).font(TTFont.headline()).foregroundStyle(TTColor.textPrimary)
                            ForEach(ex.orderedSets.filter { $0.isCompleted }) { set in
                                HStack {
                                    Text("Set \(set.setNumber)").font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
                                    Spacer()
                                    Text(TTFormat.weightReps(set.weight, reps: set.reps))
                                        .font(TTFont.numeric(15, weight: .semibold)).foregroundStyle(TTColor.textPrimary)
                                }
                            }
                            if !ex.notesSnapshot.isEmpty {
                                Text(ex.notesSnapshot).font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
                            }
                        }
                        .padding(TTSpace.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
                    }
                }
                .padding(TTSpace.md)
            }
        }
        .navigationTitle(session.nameSnapshot)
        .navigationBarTitleDisplayMode(.inline)
    }
}
