import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct YouView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context

    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var importCandidate: BackupFile?
    @State private var importData: Data?
    @State private var alert: SettingsAlert?

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            ZStack {
                TTBackground()
                ScrollView {
                    VStack(spacing: TTSpace.lg) {
                        trainingSection(settings)
                        coachingSection
                        dataSection
                        appearanceSection(settings)
                        aboutSection
                    }
                    .padding(TTSpace.md)
                    .padding(.bottom, TTSpace.xxl)
                }
            }
            .navigationTitle("You")
        }
        .sheet(item: $exportURL) { url in
            ShareSheet(items: [url])
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            handleImportSelection(result)
        }
        .sheet(item: $importCandidate) { file in
            ImportConfirmView(file: file) { mode in
                performImport(file: file, mode: mode)
            }
        }
        .alert(item: $alert) { a in
            Alert(title: Text(a.title), message: Text(a.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: Training

    private func trainingSection(_ settings: AppSettings) -> some View {
        SettingsCard(title: "Training") {
            SettingsRow(icon: "scalemass.fill", title: "Units") {
                Picker("", selection: Binding(
                    get: { settings.weightUnit },
                    set: { settings.weightUnit = $0 }
                )) {
                    ForEach(WeightUnit.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            TTDivider()
            SettingsRow(icon: "timer", title: "Default rest") {
                Menu {
                    ForEach(AppSettings.restPresets, id: \.self) { preset in
                        Button(TTFormat.rest(preset)) { settings.defaultRestSeconds = preset }
                    }
                } label: {
                    menuValue(TTFormat.rest(settings.defaultRestSeconds))
                }
            }
            TTDivider()
            SettingsRow(icon: "play.circle", title: "Auto-start rest timer") {
                Toggle("", isOn: Binding(get: { settings.autoStartRest }, set: { settings.autoStartRest = $0 }))
                    .labelsHidden().tint(TTColor.brandRed)
            }
            TTDivider()
            SettingsRow(icon: "speaker.wave.2.fill", title: "Rest alert sound") {
                Toggle("", isOn: Binding(get: { settings.restAlertSound }, set: { settings.restAlertSound = $0 }))
                    .labelsHidden().tint(TTColor.brandRed)
            }
        }
    }

    // MARK: Coaching

    private var coachingSection: some View {
        SettingsCard(title: "Coaching") {
            NavigationLink { CoachesView() } label: {
                SettingsRow(icon: "person.2.fill", title: "My Coaches") {
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(TTColor.textTertiary)
                }
            }
            TTDivider()
            NavigationLink { YouTubeKeyView() } label: {
                SettingsRow(icon: "key.fill", title: "YouTube search key") {
                    HStack(spacing: 6) {
                        Text(settings.hasYouTubeAPIKey ? "On" : "Off")
                            .font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(TTColor.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: Data

    private var dataSection: some View {
        SettingsCard(title: "Data") {
            Button(action: exportBackup) {
                SettingsRow(icon: "square.and.arrow.up", title: "Export backup") {
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(TTColor.textTertiary)
                }
            }
            .buttonStyle(.plain)
            TTDivider()
            Button { showingImporter = true } label: {
                SettingsRow(icon: "square.and.arrow.down", title: "Import backup") {
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(TTColor.textTertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Appearance

    private func appearanceSection(_ settings: AppSettings) -> some View {
        SettingsCard(title: "Appearance") {
            SettingsRow(icon: "circle.lefthalf.filled", title: "Theme") {
                Picker("", selection: Binding(
                    get: { settings.appearance },
                    set: { settings.appearance = $0 }
                )) {
                    ForEach(AppearancePreference.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        SettingsCard(title: "About") {
            SettingsRow(icon: "info.circle", title: "Version") {
                Text(Bundle.main.appVersionString).font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)
            }
            TTDivider()
            Link(destination: URL(string: "https://tubetrainer.app")!) {
                SettingsRow(icon: "globe", title: "TubeTrainer.app") {
                    Image(systemName: "arrow.up.forward").font(.footnote.weight(.semibold)).foregroundStyle(TTColor.textTertiary)
                }
            }
            TTDivider()
            NavigationLink { PrivacyView() } label: {
                SettingsRow(icon: "hand.raised.fill", title: "Privacy") {
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(TTColor.textTertiary)
                }
            }
        }
    }

    private func menuValue(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text).font(TTFont.subheadline()).foregroundStyle(TTColor.brandRed)
            Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(TTColor.textTertiary)
        }
    }

    // MARK: Export / Import actions

    private func exportBackup() {
        do {
            exportURL = try BackupService.exportToTemporaryFile(context: context, unit: settings.weightUnit)
            TTHaptics.lightTick()
        } catch {
            alert = SettingsAlert(title: "Export failed", message: "Couldn't create the backup file.")
        }
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let file = try BackupService.validate(data)
                importData = data
                importCandidate = file
            } catch let e as BackupError {
                alert = SettingsAlert(title: "Can't import", message: e.errorDescription ?? "Unknown error.")
            } catch {
                alert = SettingsAlert(title: "Can't import", message: "That file couldn't be read.")
            }
        case .failure:
            alert = SettingsAlert(title: "Can't import", message: "No file was selected.")
        }
    }

    private func performImport(file: BackupFile, mode: ImportMode) {
        do {
            let count = try BackupService.importBackup(file, mode: mode, context: context)
            TTHaptics.workoutCompleted()
            alert = SettingsAlert(title: "Import complete", message: "Restored \(count) items.")
        } catch {
            alert = SettingsAlert(title: "Import failed", message: "Your existing data was not changed.")
        }
    }
}

// MARK: - Alert model

struct SettingsAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Settings building blocks

struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: TTSpace.xs) {
            TTSectionHeader(title: title)
            VStack(spacing: 0) { content }
                .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous))
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    @ViewBuilder var trailing: Trailing
    var body: some View {
        HStack(spacing: TTSpace.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(TTColor.brandRed)
                .frame(width: 28)
            Text(title).font(TTFont.body()).foregroundStyle(TTColor.textPrimary)
            Spacer()
            trailing
        }
        .padding(.horizontal, TTSpace.md)
        .frame(minHeight: 52)
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Privacy

struct PrivacyView: View {
    var body: some View {
        ZStack {
            TTBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: TTSpace.md) {
                    Text("Your workouts stay on your device.")
                        .font(TTFont.title2()).foregroundStyle(TTColor.textPrimary)
                    Text("""
TubeTrainer has no account, no server and no analytics. Everything you log lives locally in the app and only leaves your device if you export a backup yourself.

The app talks to YouTube only to find, preview and open coaching videos you choose. We never download or store the videos themselves — only links and basic metadata like the title and thumbnail.

If you add your own YouTube API key for in-app search, it's stored locally on this device and used solely to talk to Google's YouTube service.
""")
                    .font(TTFont.body()).foregroundStyle(TTColor.textSecondary)
                }
                .padding(TTSpace.md)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
