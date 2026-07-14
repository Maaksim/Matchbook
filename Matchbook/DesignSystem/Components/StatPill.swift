import SwiftUI

/// Equal-width rounded chip showing a bold Unbounded number and a small uppercase
/// Onest caption. `highlighted` swaps in the gold tokens for podium-style stats;
/// callers must supply `accessibilityLabel` so VoiceOver announces the highlighted
/// meaning (e.g. "5 podium finishes") rather than just a color change.
struct StatPill: View {
    /// Pre-formatted number — the caller formats it (`.formatted()`), the pill only styles it.
    let value: String
    let label: LocalizedStringResource
    var highlighted: Bool = false
    let accessibilityLabel: LocalizedStringResource

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.display(size: 26))
                .foregroundStyle(highlighted ? Color.goldAccentText : Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.ui(size: 9, weight: .semibold, relativeTo: .caption2))
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(highlighted ? Color.goldAccentText.opacity(0.8) : Color.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background {
            if highlighted {
                LinearGradient.goldGradient
            } else {
                Color.chipTint
            }
        }
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

#Preview("StatPill") {
    HStack(spacing: 12) {
        StatPill(value: 12.formatted(), label: "stat_tournaments_key", accessibilityLabel: Counts.tournaments(12))
        StatPill(value: 34.formatted(), label: "stat_goals_key", accessibilityLabel: Counts.goals(34))
        StatPill(value: 5.formatted(), label: "stat_podiums_key", highlighted: true, accessibilityLabel: "showcase_podiums_accessibility_key")
    }
    .padding(24)
    .background(Color.screenBackground)
}
