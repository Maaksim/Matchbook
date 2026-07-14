import SwiftUI

struct MatchbookTabItem {
    let title: LocalizedStringResource
    let icon: Image
}

/// Translucent/blurred tab bar. The active slot shows a filled icon in brandGreen
/// with a bold label; inactive slots show an outlined icon in gray with a
/// regular-weight label. Intended to be placed via `.safeAreaInset(edge: .bottom)`.
struct MatchbookTabBar: View {
    let items: [MatchbookTabItem]
    @Binding var selection: Int

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.hairline)
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    TabBarButton(item: items[index], isSelected: index == selection) {
                        selection = index
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
        .background(Color.screenBackground)
    }
}

private struct TabBarButton: View {
    let item: MatchbookTabItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                item.icon
                    .resizable()
                    .scaledToFit()
                    .fontWeight(isSelected ? .semibold : .regular)
                    .frame(width: 22, height: 22)

                Text(item.title)
                    .font(.ui(size: 10, weight: isSelected ? .semibold : .regular, relativeTo: .caption2))
            }
            .foregroundStyle(isSelected ? Color.brandGreen : Color.textMuted)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.title))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview("MatchbookTabBar") {
    @Previewable @State var selection = 0

    ZStack {
        Color.screenBackground.ignoresSafeArea()
        Text(verbatim: "Screen content")
            .font(.ui(size: 15))
            .foregroundStyle(Color.textMuted)
    }
    .safeAreaInset(edge: .bottom) {
        MatchbookTabBar(
            items: [
                MatchbookTabItem(title: "tab_album_key",
                                 icon: Image(.iconTabAlbum)),
                MatchbookTabItem(title: "tab_tournaments_key",
                                 icon: Image(.iconTabTournament)),
                MatchbookTabItem(title: "tab_profile_key",
                                 icon: Image(.iconTabProfile))
            ],
            selection: $selection
        )
    }
}
