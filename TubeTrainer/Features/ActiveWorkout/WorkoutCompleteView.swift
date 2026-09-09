import SwiftUI
import SwiftData

struct WorkoutCompleteView: View {
    let session: WorkoutSession
    var onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appear = false
    @State private var prs: [PerformanceStore.PRHighlight] = []

    private var workingSets: Int {
        session.orderedExercises.reduce(0) { $0 + $1.orderedSets.filter { $0.isCompleted }.count }
    }
    private var totalVolume: Double {
        session.orderedExercises.reduce(0) { acc, ex in
            acc + ex.orderedSets.filter { $0.isCompleted }.reduce(0) { $0 + $1.volume }
        }
    }

    var body: some View {
        ZStack {
            TTBackground()
            ScrollView {
                VStack(spacing: TTSpace.lg) {
                    Spacer(minLength: TTSpace.xl)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(TTColor.brandRed)
                        .scaleEffect(appear ? 1 : 0.5)
                        .opacity(appear ? 1 : 0)

                    VStack(spacing: TTSpace.xs) {
                        Text("\(session.nameSnapshot) Complete")
                            .font(TTFont.title().weight(.heavy))
                            .foregroundStyle(TTColor.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(TTFormat.mediumDate(session.startedAt))
                            .font(TTFont.subheadline())
                            .foregroundStyle(TTColor.textSecondary)
                    }

                    statsGrid

                    if !prs.isEmpty {
                        prSection
                    }

                    Spacer(minLength: TTSpace.lg)
                }
                .padding(TTSpace.md)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)
            }

            VStack {
                Spacer()
                TTPrimaryButton(title: "Done", systemImage: "checkmark") { onDone() }
                    .padding(TTSpace.md)
                    .background(
                        LinearGradient(colors: [TTColor.backgroundPrimary.opacity(0), TTColor.backgroundPrimary],
                                       startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                    )
            }
        }
        .onAppear {
            prs = PerformanceStore.detectPRs(in: session, unit: settings.weightUnit, context: context)
            withAnimation(reduceMotion ? .none : TTAnim.gentle.delay(0.1)) { appear = true }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: TTSpace.sm) {
            statCard(value: TTFormat.duration(session.durationSeconds), label: "Duration", symbol: "clock.fill")
            statCard(value: "\(workingSets)", label: "Working sets", symbol: "checkmark.circle.fill")
            statCard(value: volumeText, label: "Volume", symbol: "scalemass.fill")
        }
    }

    private var volumeText: String {
        if totalVolume <= 0 { return "—" }
        let rounded = (totalVolume / 5).rounded() * 5
        return "\(TTFormat.number(rounded)) \(settings.weightUnit.label)"
    }

    private func statCard(value: String, label: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.subheadline).foregroundStyle(TTColor.brandRed)
            Text(value)
                .font(TTFont.numeric(20, weight: .bold))
                .foregroundStyle(TTColor.textPrimary)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TTSpace.md)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous))
    }

    private var prSection: some View {
        VStack(alignment: .leading, spacing: TTSpace.sm) {
            HStack(spacing: TTSpace.xs) {
                Image(systemName: "trophy.fill").foregroundStyle(TTColor.warning)
                Text("\(prs.count) Personal \(prs.count == 1 ? "Record" : "Records")")
                    .font(TTFont.title3())
                    .foregroundStyle(TTColor.textPrimary)
            }
            ForEach(prs) { pr in
                HStack(spacing: TTSpace.sm) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundStyle(TTColor.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pr.exerciseName).font(TTFont.subheadline().weight(.semibold))
                            .foregroundStyle(TTColor.textPrimary)
                        Text(pr.text).font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
                    }
                    Spacer()
                }
                .padding(TTSpace.sm)
                .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
            }
        }
    }
}
