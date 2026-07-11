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

#Preview("CardStyle") {
    VStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
            Text("Regional Cup")
                .font(.display(size: 20))
                .foregroundStyle(Color.textPrimary)
            Text("June 12 – June 14")
                .font(.ui(size: 13))
                .foregroundStyle(Color.textMuted)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()

        Text("Small radius card")
            .font(.ui(size: 15))
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(cornerRadius: 13)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.screenBackground)
}
