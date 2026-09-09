import SwiftUI

// MARK: - Video hero (coaching attached)
//
// The coaching media presented as part of the exercise. Tapping the thumbnail
// expands an inline compliant player; a prominent Open-in-YouTube fallback and a
// graceful "unavailable" state keep the workout usable offline.

struct TTVideoHero: View {
    let source: CoachingSource
    var compact: Bool = false
    var onChangeCoach: (() -> Void)?

    @State private var isPlaying = false
    @State private var playbackFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if isPlaying, !playbackFailed, let videoID = source.videoID {
                    YouTubePlayerView(videoID: videoID, startSeconds: source.startSeconds) {
                        playbackFailed = true
                    }
                } else {
                    thumbnail
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(16.0/9.0, contentMode: .fit)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
            .overlay(alignment: .topLeading) { contentTypeBadge }
            .animation(TTAnim.standard, value: isPlaying)

            metaBar
        }
    }

    private var thumbnail: some View {
        Button {
            if source.videoID != nil {
                withAnimation(TTAnim.standard) { isPlaying = true }
                TTHaptics.lightTick()
            } else {
                OpenYouTube.open(canonicalURL: source.canonicalURL)
            }
        } label: {
            ZStack {
                TTThumbnail(urlString: source.thumbnailURL, contentType: source.contentType)
                LinearGradient(colors: [.clear, .black.opacity(0.35)], startPoint: .center, endPoint: .bottom)
                Circle()
                    .fill(TTColor.brandRed)
                    .frame(width: 58, height: 58)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(x: 2)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 10, y: 4)

                if let start = source.startSeconds, start > 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            TTBadge(text: "Starts \(TTFormat.rest(start))", systemImage: "clock.fill", style: .neutral)
                                .padding(TTSpace.xs)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play coaching video: \(source.title)")
    }

    @ViewBuilder private var contentTypeBadge: some View {
        if source.contentType == .short {
            TTBadge(text: "Short", systemImage: "bolt.fill", style: .brand)
                .padding(TTSpace.xs)
        }
    }

    private var metaBar: some View {
        HStack(alignment: .top, spacing: TTSpace.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(source.channelName.isEmpty ? "YouTube" : source.channelName)
                    .font(TTFont.footnote().weight(.semibold))
                    .foregroundStyle(TTColor.brandRed)
                Text(source.title)
                    .font(TTFont.subheadline().weight(.medium))
                    .foregroundStyle(TTColor.textPrimary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Menu {
                Button {
                    OpenYouTube.open(canonicalURL: source.canonicalURL)
                } label: { Label("Open in YouTube", systemImage: "arrow.up.forward.app") }
                if let onChangeCoach {
                    Button { onChangeCoach() } label: { Label("Change coach", systemImage: "arrow.triangle.2.circlepath") }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(TTColor.textSecondary)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Coaching options")
        }
        .padding(.top, TTSpace.sm)
    }
}

// MARK: - Empty coach discovery panel (no coaching attached)
//
// Never blank space — a media-shaped panel that makes an incomplete library feel
// exciting to complete.

struct TTEmptyCoachView: View {
    let exerciseName: String
    var onRecommended: () -> Void
    var onMyCoaches: () -> Void
    var onSearch: () -> Void

    var body: some View {
        VStack(spacing: TTSpace.md) {
            VStack(spacing: TTSpace.xs) {
                Image(systemName: "play.rectangle.on.rectangle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(TTColor.brandRed)
                    .padding(.bottom, 2)
                Text("Find your \(exerciseName) coach")
                    .font(TTFont.title3())
                    .foregroundStyle(TTColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Save the explanation that makes this exercise click for you.")
                    .font(TTFont.subheadline())
                    .foregroundStyle(TTColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: TTSpace.xs) {
                discoveryButton("Recommended", "sparkles", action: onRecommended)
                discoveryButton("My Coaches", "person.2.fill", action: onMyCoaches)
                discoveryButton("Search", "magnifyingglass", action: onSearch)
            }
        }
        .padding(TTSpace.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous)
                .fill(TTColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: TTRadius.lg, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [TTColor.brandRed.opacity(0.4), TTColor.separator],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 1, dash: [6, 5])
                        )
                )
        )
    }

    private func discoveryButton(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            TTHaptics.lightTick()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 18, weight: .semibold))
                Text(title).font(TTFont.caption())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .foregroundStyle(TTColor.textPrimary)
            .background(TTColor.controlFill, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
        }
        .buttonStyle(TTCardPressStyle())
    }
}

// MARK: - Unavailable media state

struct TTVideoUnavailable: View {
    let canonicalURL: String
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: TTSpace.sm) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 30))
                .foregroundStyle(TTColor.textSecondary)
            Text("Video unavailable right now")
                .font(TTFont.headline())
                .foregroundStyle(TTColor.textPrimary)
            HStack(spacing: TTSpace.xs) {
                if let onRetry {
                    TTSecondaryButton(title: "Retry", systemImage: "arrow.clockwise", fullWidth: false) { onRetry() }
                }
                TTSecondaryButton(title: "Open in YouTube", systemImage: "arrow.up.forward.app", fullWidth: false) {
                    OpenYouTube.open(canonicalURL: canonicalURL)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16.0/9.0, contentMode: .fit)
        .background(TTColor.surface, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
    }
}
