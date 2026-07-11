import SwiftUI

/// Equal-width rounded chip showing a bold Unbounded number and a small uppercase
/// Onest caption. `highlighted` swaps in the gold tokens for podium-style stats;
/// callers must supply `accessibilityLabel` so VoiceOver announces the highlighted
/// meaning (e.g. "5 podium finishes") rather than just a color change.
struct StatPill: View {
    let value: String
    let label: String
    var highlighted: Bool = false
    let accessibilityLabel: String

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
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("StatPill") {
    HStack(spacing: 12) {
        StatPill(value: "12", label: "Tournaments", accessibilityLabel: "12 tournaments")
        StatPill(value: "34", label: "Goals", accessibilityLabel: "34 goals")
        StatPill(value: "5", label: "Podiums", highlighted: true, accessibilityLabel: "5 podium finishes")
    }
    .padding(24)
    .background(Color.screenBackground)
}
