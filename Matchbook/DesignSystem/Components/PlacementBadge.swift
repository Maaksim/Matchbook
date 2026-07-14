import SwiftUI

/// Pill with a medal emoji and a placement label (e.g. "Чемпіони"), gold gradient
/// background, dark gold text. The emoji is decorative to VoiceOver; the label is
/// exposed as the accessibility value so it reads "Місце, Чемпіони" instead of
/// speaking the emoji glyph.
///
/// `label` is deliberately a plain `String`, not a `LocalizedStringResource`: it renders
/// `Tournament.placementLabel`, which is user-entered content and passes through untouched
/// in any locale (see `Localization.swift`, rule 4). Only the badge's own accessibility
/// label — the word "Місце" — is localized.
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
        .accessibilityLabel(Text("placement_accessibility_key"))
        .accessibilityValue(label)
    }
}

#Preview("PlacementBadge") {
    VStack(spacing: 12) {
        PlacementBadge(medal: "🥇", label: "Чемпіони")
        PlacementBadge(medal: "🥈", label: "Фіналісти")
        PlacementBadge(medal: "🥉", label: "3-тє місце")
    }
    .padding(24)
    .background(Color.screenBackground)
}
