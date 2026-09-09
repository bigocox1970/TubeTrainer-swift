import SwiftUI

/// Compact persistent rest timer with a progress ring, +15s and skip.
struct RestTimerBar: View {
    @Bindable var engine: RestTimerEngine

    var body: some View {
        HStack(spacing: TTSpace.sm) {
            ZStack {
                Circle()
                    .stroke(TTColor.controlFill, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(TTColor.brandRed, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: engine.progress)
                Image(systemName: "timer")
                    .font(.caption).foregroundStyle(TTColor.textSecondary)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 0) {
                Text("Rest").font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
                Text(TTFormat.clock(engine.remaining))
                    .font(TTFont.numeric(22, weight: .bold))
                    .foregroundStyle(TTColor.textPrimary)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(TTAnim.quick, value: engine.remaining)
            }

            Spacer()

            Button {
                engine.add(seconds: 15)
                TTHaptics.lightTick()
            } label: {
                Text("+15")
                    .font(TTFont.subheadline().weight(.bold))
                    .foregroundStyle(TTColor.textPrimary)
                    .frame(width: 52, height: 40)
                    .background(TTColor.controlFill, in: Capsule())
            }
            .buttonStyle(.plain)

            Button {
                engine.skip()
                TTHaptics.lightTick()
            } label: {
                Text("Skip")
                    .font(TTFont.subheadline().weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 40)
                    .background(TTColor.brandRed, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(TTSpace.sm)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous)
                .strokeBorder(TTColor.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 16, y: 6)
    }
}

// MARK: - Exercise notes (quick, visually secondary)

struct ExerciseNotesView: View {
    @Bindable var exSession: ExerciseSession
    @Environment(\.modelContext) private var context
    @State private var expanded = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: TTSpace.xs) {
            Button {
                withAnimation(TTAnim.quick) { expanded.toggle() }
                if expanded { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { focused = true } }
            } label: {
                HStack(spacing: TTSpace.xs) {
                    Image(systemName: "note.text")
                    Text(exSession.notesSnapshot.isEmpty ? "Add a note" : "Note")
                        .font(TTFont.subheadline().weight(.semibold))
                    if !exSession.notesSnapshot.isEmpty, !expanded {
                        Text("·").foregroundStyle(TTColor.textTertiary)
                        Text(exSession.notesSnapshot)
                            .font(TTFont.subheadline())
                            .foregroundStyle(TTColor.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption)
                }
                .foregroundStyle(exSession.notesSnapshot.isEmpty ? TTColor.textSecondary : TTColor.textPrimary)
            }
            .buttonStyle(.plain)

            if expanded {
                TextField("Seat 4. Keep elbows slightly forward.", text: notesBinding, axis: .vertical)
                    .font(TTFont.body())
                    .foregroundStyle(TTColor.textPrimary)
                    .focused($focused)
                    .lineLimit(2...5)
                    .padding(TTSpace.sm)
                    .background(TTColor.controlFill, in: RoundedRectangle(cornerRadius: TTRadius.sm, style: .continuous))
            }
        }
        .padding(TTSpace.sm)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { exSession.notesSnapshot },
            set: { newValue in
                exSession.notesSnapshot = newValue
                // Persist back to the exercise so the cue carries forward.
                exSession.exercise?.notes = newValue
                try? context.save()
            }
        )
    }
}
