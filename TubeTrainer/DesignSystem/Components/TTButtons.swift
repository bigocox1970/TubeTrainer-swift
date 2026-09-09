import SwiftUI

// MARK: - Primary button (brand red, high-emphasis)

struct TTPrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading: Bool = false
    var fullWidth: Bool = true
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: {
            TTHaptics.lightTick()
            action()
        }) {
            HStack(spacing: TTSpace.xs) {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage).font(.headline)
                }
                Text(title)
                    .font(TTFont.headline().weight(.bold))
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: 54)
            .padding(.horizontal, TTSpace.lg)
            .foregroundStyle(.white)
        }
        .buttonStyle(TTPressStyle(background: TTColor.brandRed, pressed: TTColor.brandRedPressed, radius: TTRadius.md))
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(isLoading)
    }
}

// MARK: - Secondary button (surface, medium emphasis)

struct TTSecondaryButton: View {
    let title: String
    var systemImage: String?
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: {
            TTHaptics.lightTick()
            action()
        }) {
            HStack(spacing: TTSpace.xs) {
                if let systemImage {
                    Image(systemName: systemImage).font(.headline)
                }
                Text(title).font(TTFont.headline())
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: 54)
            .padding(.horizontal, TTSpace.lg)
            .foregroundStyle(TTColor.textPrimary)
        }
        .buttonStyle(TTPressStyle(background: TTColor.controlFill, pressed: TTColor.controlFillActive, radius: TTRadius.md))
    }
}

// MARK: - Icon button (circular, low chrome)

struct TTIconButton: View {
    let systemImage: String
    var size: CGFloat = 44
    var tint: Color = TTColor.textPrimary
    var background: Color = TTColor.controlFill
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            TTHaptics.lightTick()
            action()
        }) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(background, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Text link button

struct TTTextButton: View {
    let title: String
    var color: Color = TTColor.brandRed
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(TTFont.headline())
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared press style (scale + color)

struct TTPressStyle: ButtonStyle {
    var background: Color
    var pressed: Color
    var radius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? pressed : background,
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(TTAnim.snappy, value: configuration.isPressed)
    }
}

/// Subtle scale-only press feedback for tappable cards/rows.
struct TTCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(TTAnim.snappy, value: configuration.isPressed)
    }
}
