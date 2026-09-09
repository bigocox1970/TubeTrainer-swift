import SwiftUI

// MARK: - App background

/// The signature dark gradient backdrop. Subtle warmth at the top, deep black below.
struct TTBackground: View {
    var body: some View {
        TTColor.backgroundPrimary
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [TTColor.brandRed.opacity(0.10), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 260)
                .blur(radius: 30)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
    }
}

// MARK: - Section header

struct TTSectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(TTFont.caption())
                .tracking(1.2)
                .foregroundStyle(TTColor.textSecondary)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(TTFont.footnote().weight(.semibold))
                        .foregroundStyle(TTColor.brandRed)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Badge / chip

enum TTBadgeStyle {
    case coach       // green-ish, "coached"
    case needsCoach  // muted red, "find a coach"
    case neutral
    case brand

    var fg: Color {
        switch self {
        case .coach: return TTColor.success
        case .needsCoach: return TTColor.brandRed
        case .neutral: return TTColor.textSecondary
        case .brand: return .white
        }
    }
    var bg: Color {
        switch self {
        case .coach: return TTColor.success.opacity(0.15)
        case .needsCoach: return TTColor.brandRedSoft
        case .neutral: return TTColor.controlFill
        case .brand: return TTColor.brandRed
        }
    }
}

struct TTBadge: View {
    let text: String
    var systemImage: String?
    var style: TTBadgeStyle = .neutral

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(TTFont.caption())
        }
        .foregroundStyle(style.fg)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(style.bg, in: Capsule())
    }
}

// MARK: - Search field

struct TTSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var onSubmit: (() -> Void)?

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: TTSpace.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(TTColor.textSecondary)
            TextField(placeholder, text: $text)
                .font(TTFont.body())
                .foregroundStyle(TTColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .submitLabel(.search)
                .onSubmit { onSubmit?() }
            if !text.isEmpty {
                Button {
                    text = ""
                    TTHaptics.lightTick()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(TTColor.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, TTSpace.sm)
        .frame(height: 46)
        .background(TTColor.controlFill, in: RoundedRectangle(cornerRadius: TTRadius.md, style: .continuous))
    }
}

// MARK: - Pill filter chip

struct TTFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            TTHaptics.lightTick()
            action()
        } label: {
            Text(title)
                .font(TTFont.subheadline().weight(.semibold))
                .foregroundStyle(isSelected ? .white : TTColor.textSecondary)
                .padding(.horizontal, TTSpace.sm)
                .padding(.vertical, 8)
                .background(
                    isSelected ? TTColor.brandRed : TTColor.controlFill,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty state (generic, product-quality)

struct TTEmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: TTSpace.sm) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(TTColor.textTertiary)
            Text(title)
                .font(TTFont.title3())
                .foregroundStyle(TTColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(TTFont.subheadline())
                .foregroundStyle(TTColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(TTSpace.xl)
    }
}

// MARK: - Divider

struct TTDivider: View {
    var body: some View {
        Rectangle()
            .fill(TTColor.separator)
            .frame(height: 1)
    }
}
