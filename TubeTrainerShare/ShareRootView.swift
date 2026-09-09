import SwiftUI
import SwiftData

/// The Share Extension UI: preview the shared YouTube link, search exercises,
/// and save it as that exercise's coach — all without leaving YouTube.
struct ShareRootView: View {
    let rawURL: String?
    var onClose: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var parsed: YouTubeURL.Parsed?
    @State private var preview: VideoResult?
    @State private var query = ""
    @State private var savedExercise: String?
    @State private var didStartResolve = false

    private var isValid: Bool { parsed != nil }

    private var filtered: [Exercise] {
        exercises.filter { ExerciseSearch.matches(query: query, exercise: $0) }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
                .onTapGesture { onClose() }
            VStack {
                Spacer(minLength: 0)
                card
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: setup)
    }

    private var card: some View {
        VStack(spacing: 0) {
            grabber
            if let savedExercise {
                successView(savedExercise)
            } else if isValid {
                pickerView
            } else {
                invalidView
            }
        }
        .background(TTColor.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: TTRadius.xl, style: .continuous))
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .frame(maxHeight: 620)
    }

    private var grabber: some View {
        Capsule().fill(TTColor.separator)
            .frame(width: 40, height: 5)
            .padding(.top, TTSpace.sm)
    }

    // MARK: Picker

    private var pickerView: some View {
        VStack(spacing: TTSpace.sm) {
            header
            previewRow
            searchField
            Divider().overlay(TTColor.separator)
            if filtered.isEmpty {
                emptyResults
            } else {
                ScrollView {
                    LazyVStack(spacing: TTSpace.xs) {
                        ForEach(filtered) { exercise in
                            Button { save(to: exercise) } label: { exerciseRow(exercise) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, TTSpace.md)
                    .padding(.bottom, TTSpace.md)
                }
            }
        }
        .padding(.top, TTSpace.xs)
    }

    private var header: some View {
        HStack {
            Text("Save to an exercise")
                .font(TTFont.title3()).foregroundStyle(TTColor.textPrimary)
            Spacer()
            Button("Cancel") { onClose() }
                .font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)
        }
        .padding(.horizontal, TTSpace.md)
    }

    private var previewRow: some View {
        HStack(spacing: TTSpace.sm) {
            TTThumbnail(urlString: preview?.thumbnailURL ?? parsed.map { YouTubeURL.thumbnailURL(id: $0.videoID) },
                        contentType: parsed?.contentType ?? .video)
                .frame(width: 96, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: TTRadius.sm, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(preview?.title.isEmpty == false ? preview!.title : "YouTube video")
                    .font(TTFont.subheadline().weight(.semibold))
                    .foregroundStyle(TTColor.textPrimary).lineLimit(2)
                Text(preview?.channelName.isEmpty == false ? preview!.channelName : "Choose where to save it")
                    .font(TTFont.caption()).foregroundStyle(TTColor.textSecondary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, TTSpace.md)
    }

    private var searchField: some View {
        HStack(spacing: TTSpace.xs) {
            Image(systemName: "magnifyingglass").foregroundStyle(TTColor.textSecondary)
            TextField("Search exercises", text: $query)
                .foregroundStyle(TTColor.textPrimary)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
        }
        .padding(.horizontal, TTSpace.sm)
        .frame(height: 44)
        .background(TTColor.controlFill, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
        .padding(.horizontal, TTSpace.md)
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(spacing: TTSpace.sm) {
            Image(systemName: exercise.category.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(TTColor.textSecondary)
                .frame(width: 36, height: 36)
                .background(TTColor.controlFill, in: RoundedRectangle(cornerRadius: TTRadius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name).font(TTFont.subheadline().weight(.semibold))
                    .foregroundStyle(TTColor.textPrimary)
                Text(exercise.category.shortName)
                    .font(TTFont.caption()).foregroundStyle(TTColor.textSecondary)
            }
            Spacer()
            if exercise.hasCoach {
                Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(TTColor.textTertiary)
            }
            Image(systemName: "plus.circle.fill").foregroundStyle(TTColor.brandRed)
        }
        .padding(TTSpace.sm)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
    }

    private var emptyResults: some View {
        VStack(spacing: TTSpace.xs) {
            Text("No matches").font(TTFont.headline()).foregroundStyle(TTColor.textPrimary)
            Text("Try a different search.").font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(TTSpace.xl)
    }

    // MARK: Invalid / success

    private var invalidView: some View {
        VStack(spacing: TTSpace.sm) {
            Image(systemName: "link.badge.plus").font(.system(size: 34)).foregroundStyle(TTColor.warning)
            Text("Not a YouTube link").font(TTFont.title3()).foregroundStyle(TTColor.textPrimary)
            Text("Share a YouTube video or Short to save it as coaching.")
                .font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)
                .multilineTextAlignment(.center)
            Button("Close") { onClose() }
                .font(TTFont.headline()).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(TTColor.brandRed, in: RoundedRectangle(cornerRadius: TTRadius.md))
        }
        .padding(TTSpace.lg)
    }

    private func successView(_ name: String) -> some View {
        VStack(spacing: TTSpace.sm) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 46)).foregroundStyle(TTColor.success)
            Text("Saved to \(name)").font(TTFont.title3()).foregroundStyle(TTColor.textPrimary)
            Text("It's now this exercise's coach in TubeTrainer.")
                .font(TTFont.subheadline()).foregroundStyle(TTColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(TTSpace.xl)
    }

    // MARK: Actions

    private func setup() {
        guard !didStartResolve else { return }
        didStartResolve = true
        parsed = rawURL.flatMap { YouTubeURL.parse($0) }
        if let p = parsed {
            preview = CoachingLibrary.result(from: p)
            query = ""
            resolveMetadata(for: p)
        }
    }

    private func resolveMetadata(for parsed: YouTubeURL.Parsed) {
        let service = YouTubeDiscoveryService(apiKeyProvider: { "" })
        Task {
            if var enriched = try? await service.metadata(videoID: parsed.videoID, contentType: parsed.contentType) {
                enriched.startSeconds = parsed.startSeconds
                enriched.canonicalURL = parsed.canonicalURL
                await MainActor.run { preview = enriched }
            }
        }
    }

    private func save(to exercise: Exercise) {
        let result = preview ?? parsed.map { CoachingLibrary.result(from: $0) }
        guard let result else { return }
        CoachingLibrary.attach(result, to: exercise, context: context)
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            savedExercise = exercise.name
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { onClose() }
    }
}
