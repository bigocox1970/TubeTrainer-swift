import SwiftUI

/// Clear confirmation before any destructive merge/replace import.
struct ImportConfirmView: View {
    let file: BackupFile
    var onConfirm: (ImportMode) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                TTBackground()
                VStack(alignment: .leading, spacing: TTSpace.lg) {
                    VStack(alignment: .leading, spacing: TTSpace.xs) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 40)).foregroundStyle(TTColor.brandRed)
                        Text("Restore backup")
                            .font(TTFont.title().weight(.heavy)).foregroundStyle(TTColor.textPrimary)
                        Text("Backup from \(TTFormat.mediumDate(file.exportedAt)) · v\(file.version)")
                            .font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)
                    }

                    VStack(spacing: TTSpace.xs) {
                        summaryRow("dumbbell.fill", "\(file.exercises.count) exercises")
                        summaryRow("rectangle.stack.fill", "\(file.templates.count) workouts")
                        summaryRow("clock.fill", "\(file.sessions.count) sessions")
                        summaryRow("person.2.fill", "\(file.coaches.count) coaches")
                    }
                    .padding(TTSpace.md)
                    .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous))

                    Spacer()

                    VStack(spacing: TTSpace.xs) {
                        TTPrimaryButton(title: "Merge with my data", systemImage: "arrow.triangle.merge") {
                            onConfirm(.merge); dismiss()
                        }
                        TTSecondaryButton(title: "Replace everything", systemImage: "exclamationmark.triangle") {
                            onConfirm(.replace); dismiss()
                        }
                        Text("Merge keeps what you have and adds anything missing. Replace clears your current data first.")
                            .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.top, TTSpace.xs)
                    }
                }
                .padding(TTSpace.md)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundStyle(TTColor.textSecondary)
                }
            }
        }
    }

    private func summaryRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: TTSpace.sm) {
            Image(systemName: icon).foregroundStyle(TTColor.brandRed).frame(width: 26)
            Text(text).font(TTFont.body()).foregroundStyle(TTColor.textPrimary)
            Spacer()
        }
    }
}

// MARK: - YouTube API key

struct YouTubeKeyView: View {
    @Environment(AppSettings.self) private var settings
    @State private var draft = ""

    var body: some View {
        @Bindable var settings = settings
        ZStack {
            TTBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: TTSpace.md) {
                    Text("In-app YouTube search is optional. Without a key, you can still paste any YouTube link and open Search on YouTube — that always works.")
                        .font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)

                    VStack(alignment: .leading, spacing: TTSpace.xs) {
                        Text("YOUTUBE DATA API KEY").font(TTFont.caption()).tracking(1).foregroundStyle(TTColor.textSecondary)
                        HStack {
                            SecureField("Paste key", text: $draft)
                                .font(TTFont.body()).foregroundStyle(TTColor.textPrimary)
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                            if !draft.isEmpty {
                                Button { draft = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(TTColor.textTertiary) }
                            }
                        }
                        .padding(TTSpace.sm)
                        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
                    }

                    TTPrimaryButton(title: settings.hasYouTubeAPIKey ? "Update key" : "Save key") {
                        settings.youtubeAPIKey = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                        TTHaptics.lightTick()
                    }
                    if settings.hasYouTubeAPIKey {
                        TTSecondaryButton(title: "Remove key") {
                            settings.youtubeAPIKey = ""; draft = ""
                        }
                    }

                    VStack(alignment: .leading, spacing: TTSpace.xs) {
                        Text("How to get a key").font(TTFont.headline()).foregroundStyle(TTColor.textPrimary)
                        Text("""
1. Open Google Cloud Console and create a project.
2. Enable “YouTube Data API v3”.
3. Create an API key and (recommended) restrict it to the YouTube Data API and your iOS bundle id.

The free tier allows roughly 100 searches per day. The key is stored only on this device.
""")
                        .font(TTFont.footnote()).foregroundStyle(TTColor.textSecondary)
                    }
                    .padding(TTSpace.md)
                    .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous))
                }
                .padding(TTSpace.md)
            }
        }
        .navigationTitle("YouTube search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { draft = settings.youtubeAPIKey }
    }
}
