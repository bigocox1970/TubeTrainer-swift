import SwiftUI

/// Coaching status shown as a small, non-guilt-inducing badge.
extension Exercise {
    @ViewBuilder var coachingBadge: some View {
        if let coach = primaryCoach {
            TTBadge(text: coach.channelName.isEmpty ? "Coached" : coach.channelName,
                    systemImage: "play.fill", style: .coach)
        } else {
            TTBadge(text: "Find coach", systemImage: "plus", style: .needsCoach)
        }
    }
}

/// Library/plan list row: exercise identity + category + coaching status + last perf.
struct TTExerciseRow: View {
    let exercise: Exercise
    var lastPerformance: String?
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: TTSpace.sm) {
            // Category glyph tile
            ZStack {
                RoundedRectangle(cornerRadius: TTRadius.sm, style: .continuous)
                    .fill(TTColor.controlFill)
                Image(systemName: exercise.category.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(TTColor.textSecondary)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    if exercise.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(TTColor.brandRed)
                            .accessibilityLabel("Favourite")
                    }
                    Text(exercise.name)
                        .font(TTFont.headline())
                        .foregroundStyle(TTColor.textPrimary)
                        .lineLimit(1)
                }
                HStack(spacing: TTSpace.xs) {
                    Text(exercise.category.shortName)
                        .font(TTFont.caption())
                        .foregroundStyle(TTColor.textSecondary)
                    if let lastPerformance {
                        Text("·").foregroundStyle(TTColor.textTertiary)
                        Text(lastPerformance)
                            .font(TTFont.caption())
                            .foregroundStyle(TTColor.textSecondary)
                    }
                }
            }
            Spacer(minLength: TTSpace.xs)
            exercise.coachingBadge
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TTColor.textTertiary)
            }
        }
        .padding(TTSpace.sm)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
