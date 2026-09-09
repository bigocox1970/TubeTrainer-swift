import SwiftUI

/// A subtle shimmer for redacted loading placeholders. Respects Reduce Motion.
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.06), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 1.5)
                        .offset(x: phase * geo.size.width * 1.5)
                    }
                    .allowsHitTesting(false)
                )
                .clipped()
                .onAppear {
                    withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                        phase = 1.2
                    }
                }
        }
    }
}

extension View {
    func shimmer() -> some View { modifier(Shimmer()) }
}
