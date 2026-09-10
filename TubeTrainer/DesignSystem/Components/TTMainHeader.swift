import SwiftUI

/// Consistent title header for the main tabs (Today, Library, History, You).
/// Replaces iOS large nav titles so every tab's title sits at the same spot with
/// no wasted bar space, and an optional action can share the title's line.
struct TTMainHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: TTSpace.sm) {
            Text(title)
                .font(TTFont.largeTitle())
                .foregroundStyle(TTColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, TTSpace.md)
        .padding(.top, TTSpace.xs)
        .padding(.bottom, TTSpace.sm)
        .accessibilityAddTraits(.isHeader)
    }
}

extension TTMainHeader where Trailing == EmptyView {
    init(title: String) {
        self.title = title
        self.trailing = { EmptyView() }
    }
}

/// The circular red "+" used in headers (e.g. Library → create exercise).
struct TTHeaderAddButton: View {
    var accessibilityLabel: String
    let action: () -> Void
    var body: some View {
        Button {
            TTHaptics.lightTick()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(TTColor.brandRed, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
