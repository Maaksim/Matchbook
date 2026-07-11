import SwiftUI

/// Pill with a medal emoji and a placement label (e.g. "Champions"), gold gradient
/// background, dark gold text. The emoji is decorative to VoiceOver; the label is
/// exposed as the accessibility value so it reads "Placement, Champions" instead of
/// speaking the emoji glyph.
struct PlacementBadge: View {
    let medal: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Text(medal)
                .font(.system(size: 18))
                .accessibilityHidden(true)

            Text(label)
                .font(.ui(size: 15, weight: .semibold, relativeTo: .subheadline))
                .foregroundStyle(Color.goldAccentText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            LinearGradient.goldGradient
        }
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Placement")
        .accessibilityValue(label)
    }
}

#Preview("PlacementBadge") {
    VStack(spacing: 12) {
        PlacementBadge(medal: "🥇", label: "Champions")
        PlacementBadge(medal: "🥈", label: "Finalists")
        PlacementBadge(medal: "🥉", label: "3rd Place")
    }
    .padding(24)
    .background(Color.screenBackground)
}
