import SwiftUI
import SwiftData

/// My Coaches — favorite channels. Optional; the app is complete without any.
struct CoachesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Coach.createdAt) private var coaches: [Coach]
    @Query private var exercises: [Exercise]

    @State private var adding = false

    var body: some View {
        ZStack {
            TTBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: TTSpace.sm) {
                    if coaches.isEmpty {
                        emptyState
                    } else {
                        ForEach(coaches) { coach in
                            CoachRow(coach: coach, exerciseCount: exerciseCount(for: coach)) {
                                delete(coach)
                            }
                        }
                    }
                }
                .padding(TTSpace.md)
                .padding(.bottom, TTSpace.xxl)
            }
        }
        .navigationTitle("My Coaches")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
                    .foregroundStyle(TTColor.brandRed)
            }
        }
        .sheet(isPresented: $adding) { AddCoachView() }
    }

    private var emptyState: some View {
        VStack(spacing: TTSpace.md) {
            TTEmptyState(symbol: "person.2.badge.plus",
                         title: "Who do you learn from?",
                         message: "Add the YouTube trainers you already trust — or skip this and discover videos exercise by exercise.")
            TTPrimaryButton(title: "Add a coach", systemImage: "plus") { adding = true }
        }
        .ttCard(padding: TTSpace.lg)
    }

    private func exerciseCount(for coach: Coach) -> Int {
        exercises.filter { ex in
            ex.coachingSources.contains { source in
                (coach.channelID != nil && source.channelID == coach.channelID) ||
                source.channelName.caseInsensitiveCompare(coach.name) == .orderedSame
            }
        }.count
    }

    private func delete(_ coach: Coach) {
        withAnimation { context.delete(coach); try? context.save() }
    }
}

struct CoachRow: View {
    let coach: Coach
    let exerciseCount: Int
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: TTSpace.sm) {
            ZStack {
                Circle().fill(TTColor.controlFill)
                Text(initials).font(TTFont.headline()).foregroundStyle(TTColor.textSecondary)
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(coach.name).font(TTFont.headline()).foregroundStyle(TTColor.textPrimary)
                Text(exerciseCount == 0 ? "No exercises yet" : "\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")")
                    .font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
            }
            Spacer()
            Menu {
                if let url = coach.channelURL, let u = URL(string: url) {
                    Button { UIApplication.shared.open(u) } label: { Label("Open channel", systemImage: "arrow.up.forward") }
                }
                Button(role: .destructive, action: onDelete) { Label("Remove", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis").foregroundStyle(TTColor.textSecondary)
                    .frame(width: 40, height: 40).contentShape(Rectangle())
            }
        }
        .padding(TTSpace.sm)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
    }

    private var initials: String {
        let parts = coach.name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

struct AddCoachView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var channelURL = ""

    var body: some View {
        NavigationStack {
            ZStack {
                TTBackground()
                VStack(alignment: .leading, spacing: TTSpace.md) {
                    Text("Add the name of a YouTube trainer you trust. When you find coaching, theirs gets prioritised.")
                        .font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)

                    labeledField("Coach / channel name") {
                        TextField("e.g. Jeff Nippard", text: $name)
                    }
                    labeledField("Channel link (optional)") {
                        TextField("https://youtube.com/@…", text: $channelURL)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    }
                    Spacer()
                }
                .padding(TTSpace.md)
            }
            .navigationTitle("Add coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() }.foregroundStyle(TTColor.textSecondary) }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .foregroundStyle(canSave ? TTColor.brandRed : TTColor.textTertiary).disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private func labeledField<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: TTSpace.xs) {
            Text(label.uppercased()).font(TTFont.caption()).tracking(1).foregroundStyle(TTColor.textSecondary)
            content()
                .font(TTFont.body()).foregroundStyle(TTColor.textPrimary)
                .padding(TTSpace.sm)
                .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
        }
    }

    private func save() {
        let url = channelURL.trimmingCharacters(in: .whitespaces)
        let channelID = extractChannelID(from: url)
        let coach = Coach(channelID: channelID, name: name.trimmingCharacters(in: .whitespaces),
                          channelURL: url.isEmpty ? nil : url)
        context.insert(coach)
        try? context.save()
        TTHaptics.lightTick()
        dismiss()
    }

    /// Extract a channel id from a /channel/UC… URL when present (best-effort).
    private func extractChannelID(from url: String) -> String? {
        guard let comps = URLComponents(string: url) else { return nil }
        let parts = comps.path.split(separator: "/").map(String.init)
        if let idx = parts.firstIndex(of: "channel"), idx + 1 < parts.count {
            return parts[idx + 1]
        }
        return nil
    }
}
