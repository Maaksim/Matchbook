import SwiftUI

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(Color.cardSurface)
            .clipShape(.rect(cornerRadius: cornerRadius))
            .shadow(color: Color(red: 20 / 255, green: 45 / 255, blue: 28 / 255).opacity(0.18), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 20) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}

/// Sample tournament dates for the preview. A date range is *formatted*, never concatenated:
/// `.interval` renders "12–14 черв." in Ukrainian and "Jun 12 – 14" in English off the same
/// call, which a hand-built string could never do (see `Localization.swift`, rule 3).
private var sampleTournamentDates: Range<Date> {
    let start = Date.now
    return start ..< start.addingTimeInterval(2 * 24 * 60 * 60)
}

#Preview("CardStyle") {
    VStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
            // A tournament name is user-entered content — verbatim, never localized (rule 4).
            Text(verbatim: "Кубок регіону")
                .font(.display(size: 20))
                .foregroundStyle(Color.textPrimary)
            Text(sampleTournamentDates.formatted(.interval.day().month(.abbreviated)))
                .font(.ui(size: 13))
                .foregroundStyle(Color.textMuted)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()

        Text(verbatim: "Small radius card")
            .font(.ui(size: 15))
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(cornerRadius: 13)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.screenBackground)
}
