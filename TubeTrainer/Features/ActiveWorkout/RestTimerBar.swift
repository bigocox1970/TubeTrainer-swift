import SwiftUI

/// Rest = recovery. The ring "recharges" from red → amber → green as you rest,
/// so a glance tells you how ready you are for the next set.
enum RestTimerStyle {
    /// Ring gradient, from empty/tired (red) to charged/ready (green).
    static let gradient = AngularGradient(
        gradient: Gradient(colors: [
            Color(red: 0.96, green: 0.20, blue: 0.18),
            Color(red: 1.00, green: 0.69, blue: 0.13),
            Color(red: 0.35, green: 0.82, blue: 0.42),
        ]),
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    /// Solid colour matching the current recharge progress (for labels/numbers).
    static func color(for progress: Double) -> Color {
        let p = max(0, min(1, progress))
        let stops: [(Double, Double, Double)] = [(0.96, 0.20, 0.18), (1.0, 0.69, 0.13), (0.35, 0.82, 0.42)]
        func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
        let (from, to, t): ((Double, Double, Double), (Double, Double, Double), Double) =
            p < 0.5 ? (stops[0], stops[1], p / 0.5) : (stops[1], stops[2], (p - 0.5) / 0.5)
        return Color(red: lerp(from.0, to.0, t), green: lerp(from.1, to.1, t), blue: lerp(from.2, to.2, t))
    }
}

/// Compact persistent rest timer — tap to expand into the full recharge view.
struct RestTimerBar: View {
    @Bindable var engine: RestTimerEngine
    var onExpand: () -> Void

    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: TTSpace.sm) {
                ZStack {
                    Circle().stroke(TTColor.controlFill, lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: engine.progress)
                        .stroke(RestTimerStyle.gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.25), value: engine.progress)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(RestTimerStyle.color(for: engine.progress))
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
        .buttonStyle(.plain)
    }
}

/// Full-screen "recharge" rest timer. The big ring fills red → amber → green as
/// you recover; the centre counts down. Tap the dimmed backdrop or Done to close.
struct RestTimerRechargeView: View {
    @Bindable var engine: RestTimerEngine
    var onDismiss: () -> Void

    private var color: Color { RestTimerStyle.color(for: engine.progress) }
    private var ready: Bool { engine.remaining <= 0 || !engine.isRunning }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .background(.ultraThinMaterial)
                .onTapGesture { onDismiss() }

            VStack(spacing: TTSpace.xl) {
                Text(ready ? "READY" : "RECHARGING")
                    .font(TTFont.caption().weight(.heavy)).tracking(3)
                    .foregroundStyle(color)

                ZStack {
                    Circle().stroke(TTColor.controlFill, lineWidth: 18)
                    Circle()
                        .trim(from: 0, to: engine.progress)
                        .stroke(RestTimerStyle.gradient, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: color.opacity(0.5), radius: 12)
                        .animation(.linear(duration: 0.25), value: engine.progress)

                    VStack(spacing: 4) {
                        Image(systemName: ready ? "checkmark" : "bolt.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(color)
                        Text(TTFormat.clock(engine.remaining))
                            .font(TTFont.numeric(56, weight: .bold))
                            .foregroundStyle(TTColor.textPrimary)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(TTAnim.quick, value: engine.remaining)
                        Text("of \(TTFormat.clock(engine.totalSeconds))")
                            .font(TTFont.footnote()).foregroundStyle(TTColor.textTertiary)
                    }
                }
                .frame(width: 260, height: 260)

                HStack(spacing: TTSpace.md) {
                    Button {
                        engine.add(seconds: 15); TTHaptics.lightTick()
                    } label: {
                        Label("15s", systemImage: "goforward.15")
                            .font(TTFont.headline())
                            .foregroundStyle(TTColor.textPrimary)
                            .frame(width: 110, height: 54)
                            .background(TTColor.controlFill, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.skip(); TTHaptics.lightTick(); onDismiss()
                    } label: {
                        Text(ready ? "Done" : "Skip rest")
                            .font(TTFont.headline().weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 130, height: 54)
                            .background(TTColor.brandRed, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(TTSpace.xl)
        }
        .transition(.opacity)
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
