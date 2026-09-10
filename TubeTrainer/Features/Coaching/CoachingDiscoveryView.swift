import SwiftUI
import SwiftData

/// Coaching discovery: one search over YouTube with an optional coach filter,
/// plus a keyless paste-a-link flow. Opens on recommended results for the
/// exercise; pick a coach chip to scope to that channel. Confirms before saving.
struct CoachingDiscoveryView: View {
    let exercise: Exercise
    var onSelect: (VideoResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var appEnv
    @Query(sort: \Coach.createdAt) private var coaches: [Coach]

    @State private var model: CoachingDiscoveryModel?
    @State private var confirming: VideoResult?

    /// Open a YouTube search inside the app (compliant in-app Safari). Presented via
    /// UIKit so Done returns here — to the paste field — not out to the exercise.
    /// From there the user can copy a link and paste it below, or Share → TubeTrainer.
    private func browseYouTube(_ query: String) {
        guard let url = YouTubeURL.searchURL(query: query) else { return }
        SafariPresenter.present(url)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TTBackground()
                if let model {
                    content(model)
                }
            }
            .navigationTitle("Find a coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TTColor.textSecondary)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            if model == nil {
                model = CoachingDiscoveryModel(exerciseName: exercise.name, discovery: appEnv.discovery)
            }
        }
        .sheet(item: $confirming) { result in
            CoachConfirmView(result: result, exerciseName: exercise.name) { finalResult in
                onSelect(finalResult)
                dismiss()
            }
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func content(_ model: CoachingDiscoveryModel) -> some View {
        @Bindable var model = model
        VStack(spacing: TTSpace.md) {
            // One search field. Empty = recommended results for the exercise.
            TTSearchField(text: $model.query, placeholder: "Search YouTube coaching") {
                Task { await model.load(coaches: coaches) }
            }

            // Optional coach filter: All (everyone) + a chip per saved coach.
            if !coaches.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: TTSpace.xs) {
                        TTFilterChip(title: "All", isSelected: model.selectedCoach == nil) {
                            model.selectedCoach = nil
                            Task { await model.load(coaches: coaches) }
                        }
                        ForEach(coaches) { coach in
                            TTFilterChip(title: coach.name, isSelected: model.selectedCoach?.id == coach.id) {
                                // Tapping the active coach clears the filter.
                                model.selectedCoach = model.selectedCoach?.id == coach.id ? nil : coach
                                Task { await model.load(coaches: coaches) }
                            }
                        }
                    }
                }
            }

            resultsArea(model)
        }
        .padding(TTSpace.md)
        .task { await model.load(coaches: coaches) }
    }

    @ViewBuilder
    private func resultsArea(_ model: CoachingDiscoveryModel) -> some View {
        @Bindable var model = model
        ScrollView {
            VStack(spacing: TTSpace.md) {
                pasteCard(model)

                switch model.state {
                case .idle:
                    EmptyView()
                case .loading:
                    loadingRows
                case .loaded(let results):
                    ForEach(results) { result in
                        VideoResultRow(result: result) { confirming = result }
                    }
                case .empty:
                    TTEmptyState(symbol: "sparkle.magnifyingglass", title: "Nothing found",
                                 message: "Try different words, or paste a link you already have.")
                case .failed(let message):
                    errorCard(message) { Task { await model.load(coaches: coaches) } }
                case .searchUnavailable:
                    searchUnavailableCard(model)
                }
            }
            .padding(.bottom, TTSpace.xl)
        }
    }

    private func pasteCard(_ model: CoachingDiscoveryModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: TTSpace.xs) {
            Text("Have a link?").font(TTFont.footnote().weight(.semibold))
                .foregroundStyle(TTColor.textSecondary)
            HStack(spacing: TTSpace.xs) {
                HStack {
                    Image(systemName: "link").foregroundStyle(TTColor.textTertiary)
                    TextField("Paste YouTube link", text: $model.pasteURL)
                        .font(TTFont.subheadline())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
                .padding(.horizontal, TTSpace.sm)
                .frame(height: 46)
                .background(TTColor.controlFill, in: RoundedRectangle(cornerRadius: TTRadius.sm, style: .continuous))

                Button {
                    Task {
                        if let result = await model.resolvePaste() { confirming = result }
                    }
                } label: {
                    Group {
                        if case .loading = model.pasteState { ProgressView().tint(.white) }
                        else { Image(systemName: "arrow.right") }
                    }
                    .frame(width: 46, height: 46)
                    .foregroundStyle(.white)
                    .background(TTColor.brandRed, in: RoundedRectangle(cornerRadius: TTRadius.sm, style: .continuous))
                }
                .disabled(model.pasteURL.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if case .failed(let msg) = model.pasteState {
                Text(msg).font(TTFont.caption()).foregroundStyle(TTColor.brandRed)
            }
        }
        .ttCard()
    }

    private var loadingRows: some View {
        VStack(spacing: TTSpace.md) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: TTSpace.sm) {
                    RoundedRectangle(cornerRadius: TTRadius.sm)
                        .fill(TTColor.surface)
                        .frame(width: 120, height: 68)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4).fill(TTColor.surface).frame(height: 12)
                        RoundedRectangle(cornerRadius: 4).fill(TTColor.surface).frame(width: 100, height: 10)
                    }
                    Spacer()
                }
            }
        }
        .redacted(reason: .placeholder)
        .shimmer()
    }

    private func errorCard(_ message: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: TTSpace.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title).foregroundStyle(TTColor.warning)
            Text(message).font(TTFont.subheadline())
                .foregroundStyle(TTColor.textSecondary).multilineTextAlignment(.center)
            HStack {
                TTSecondaryButton(title: "Retry", systemImage: "arrow.clockwise", fullWidth: false, action: retry)
                TTSecondaryButton(title: "Search on YouTube", fullWidth: false) { browseYouTube(exercise.name) }
            }
        }
        .ttCard(padding: TTSpace.lg)
    }

    private func searchUnavailableCard(_ model: CoachingDiscoveryModel) -> some View {
        let query = model.browseQuery
        let isDefault = model.selectedCoach == nil && model.query.trimmingCharacters(in: .whitespaces).isEmpty
        return VStack(spacing: TTSpace.sm) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 36)).foregroundStyle(TTColor.brandRed)
            Text(isDefault ? "Find a \(exercise.name) coach" : "Search YouTube")
                .font(TTFont.title3()).foregroundStyle(TTColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("Opens YouTube for “\(query)”. Pick a video you like, tap Share → TubeTrainer (or copy the link and paste it above) to set it as your coach.")
                .font(TTFont.subheadline())
                .foregroundStyle(TTColor.textSecondary)
                .multilineTextAlignment(.center)
            TTPrimaryButton(title: "Search on YouTube", systemImage: "magnifyingglass") {
                browseYouTube(query)
            }
            Text("Prefer results right here? Add a free key in Settings → YouTube search key.")
                .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .ttCard(padding: TTSpace.lg)
    }
}

// MARK: - Video result row

struct VideoResultRow: View {
    let result: VideoResult
    let action: () -> Void

    var body: some View {
        Button(action: {
            TTHaptics.lightTick()
            action()
        }) {
            HStack(spacing: TTSpace.sm) {
                TTThumbnail(urlString: result.thumbnailURL, contentType: result.contentType)
                    .frame(width: 128, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: TTRadius.sm, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        if result.contentType == .short {
                            TTBadge(text: "Short", style: .brand).scaleEffect(0.85).padding(4)
                        }
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(TTFont.subheadline().weight(.semibold))
                        .foregroundStyle(TTColor.textPrimary)
                        .lineLimit(2).multilineTextAlignment(.leading)
                    Text(result.channelName)
                        .font(TTFont.caption())
                        .foregroundStyle(TTColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(TTCardPressStyle())
    }
}

// MARK: - Confirmation ("Use this for …?")

struct CoachConfirmView: View {
    let result: VideoResult
    let exerciseName: String
    var onConfirm: (VideoResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startTimeText: String = ""
    @State private var useStartTime = false

    /// Result with the optional saved start point applied.
    private var finalResult: VideoResult {
        var r = result
        if useStartTime, let seconds = YouTubeURL.parseTimeString(startTimeText), seconds > 0 {
            r.startSeconds = seconds
            r.canonicalURL = YouTubeURL.watchURL(r.videoID, start: seconds)
        }
        return r
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TTBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: TTSpace.md) {
                        TTVideoHero(source: result.makeCoachingSource())
                            .allowsHitTesting(false)

                        Text("Use this for \(exerciseName)?")
                            .font(TTFont.title2())
                            .foregroundStyle(TTColor.textPrimary)

                        if result.contentType == .video {
                            startTimeSection
                        }

                        VStack(spacing: TTSpace.xs) {
                            TTPrimaryButton(title: "Set as My Coach", systemImage: "checkmark") {
                                TTHaptics.coachSelected()
                                onConfirm(finalResult)
                            }
                            TTSecondaryButton(title: "Choose another") { dismiss() }
                        }
                    }
                    .padding(TTSpace.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var startTimeSection: some View {
        VStack(alignment: .leading, spacing: TTSpace.xs) {
            Toggle(isOn: $useStartTime.animation(TTAnim.quick)) {
                Text("Start coaching at a specific time")
                    .font(TTFont.subheadline())
                    .foregroundStyle(TTColor.textPrimary)
            }
            .tint(TTColor.brandRed)

            if useStartTime {
                HStack {
                    Image(systemName: "clock").foregroundStyle(TTColor.textSecondary)
                    TextField("e.g. 2:14 or 134", text: $startTimeText)
                        .font(TTFont.body())
                        .keyboardType(.numbersAndPunctuation)
                }
                .padding(.horizontal, TTSpace.sm)
                .frame(height: 46)
                .background(TTColor.controlFill, in: RoundedRectangle(cornerRadius: TTRadius.sm, style: .continuous))
                Text("A saved start point jumps you straight to the useful part.")
                    .font(TTFont.caption()).foregroundStyle(TTColor.textTertiary)
            }
        }
        .ttCard()
    }
}
