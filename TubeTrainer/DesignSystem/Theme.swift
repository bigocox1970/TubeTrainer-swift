import SwiftUI
import UIKit

// MARK: - Semantic Colors
//
// Defined as dynamic light/dark pairs so the app fully supports the user's
// Appearance preference (System / Dark / Light). Dark is the primary identity;
// light is a deliberately designed appearance, not a washed-out afterthought.

extension Color {
    /// Build a dynamic color from dark + light UIColors.
    static func tt(dark: UInt, light: UInt) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .light ? UIColor(rgb: light) : UIColor(rgb: dark)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}

enum TTColor {
    // Backgrounds
    static let backgroundPrimary = Color.tt(dark: 0x0A0A0B, light: 0xF6F6F7)
    static let backgroundSecondary = Color.tt(dark: 0x141416, light: 0xFFFFFF)
    static let surface = Color.tt(dark: 0x1C1C1F, light: 0xFFFFFF)
    static let surfaceElevated = Color.tt(dark: 0x26262B, light: 0xFFFFFF)

    // Text
    static let textPrimary = Color.tt(dark: 0xF7F7F5, light: 0x111113)
    static let textSecondary = Color.tt(dark: 0x9A9AA2, light: 0x6B6B73)
    static let textTertiary = Color.tt(dark: 0x66666E, light: 0x9A9AA2)

    // Brand
    static let brandRed = Color.tt(dark: 0xF5322E, light: 0xE01F1B)
    static let brandRedPressed = Color.tt(dark: 0xC01F1C, light: 0xB01512)
    static let brandRedSoft = Color.tt(dark: 0x2A1414, light: 0xFDE8E7)

    // Semantic
    static let success = Color.tt(dark: 0x34C759, light: 0x248A3D)
    static let warning = Color.tt(dark: 0xFFB020, light: 0xB25E00)
    static let separator = Color.tt(dark: 0x2C2C31, light: 0xE2E2E6)

    // Fills for controls
    static let controlFill = Color.tt(dark: 0x2A2A30, light: 0xEDEDF0)
    static let controlFillActive = Color.tt(dark: 0x3A3A42, light: 0xE0E0E6)
}

// MARK: - Spacing scale

enum TTSpace {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner radius scale

enum TTRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
    static let xl: CGFloat = 28
    static let pill: CGFloat = 999
}

// MARK: - Typography tokens
//
// Rounded design for a modern, physical feel. Scales with Dynamic Type via
// relativeTo text styles.

enum TTFont {
    static func hero() -> Font { .system(size: 40, weight: .heavy, design: .rounded) }
    static func largeTitle() -> Font { .system(.largeTitle, design: .rounded).weight(.bold) }
    static func title() -> Font { .system(.title, design: .rounded).weight(.bold) }
    static func title2() -> Font { .system(.title2, design: .rounded).weight(.bold) }
    static func title3() -> Font { .system(.title3, design: .rounded).weight(.semibold) }
    static func headline() -> Font { .system(.headline, design: .rounded) }
    static func body() -> Font { .system(.body, design: .rounded) }
    static func callout() -> Font { .system(.callout, design: .rounded) }
    static func subheadline() -> Font { .system(.subheadline, design: .rounded) }
    static func footnote() -> Font { .system(.footnote, design: .rounded) }
    static func caption() -> Font { .system(.caption, design: .rounded).weight(.medium) }
    /// Tabular numerals for set-logger values.
    static func numeric(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

// MARK: - Animation tokens

enum TTAnim {
    static let quick = Animation.spring(response: 0.28, dampingFraction: 0.86)
    static let standard = Animation.spring(response: 0.38, dampingFraction: 0.82)
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.85)
    static let snappy = Animation.spring(response: 0.22, dampingFraction: 0.7)
}

// MARK: - Reusable view modifiers

extension View {
    /// Standard elevated surface card.
    func ttCard(padding: CGFloat = TTSpace.md, radius: CGFloat = TTRadius.lg) -> some View {
        self
            .padding(padding)
            .background(TTColor.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Screen-standard horizontal insets.
    func ttScreenPadding() -> some View {
        self.padding(.horizontal, TTSpace.md)
    }
}
