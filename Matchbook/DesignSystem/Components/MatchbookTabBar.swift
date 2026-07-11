import SwiftUI

struct MatchbookTabItem {
    let title: String
    let systemImage: String
    let selectedSystemImage: String
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
                    tabButton(for: items[index], index: index)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func tabButton(for item: MatchbookTabItem, index: Int) -> some View {
        let isSelected = index == selection

        Button {
            selection = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? item.selectedSystemImage : item.systemImage)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))

                Text(item.title)
                    .font(.ui(size: 10, weight: isSelected ? .semibold : .regular, relativeTo: .caption2))
            }
            .foregroundStyle(isSelected ? Color.brandGreen : Color.textMuted)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview("MatchbookTabBar") {
    @Previewable @State var selection = 0

    ZStack {
        Color.screenBackground.ignoresSafeArea()
        Text("Screen content")
            .font(.ui(size: 15))
            .foregroundStyle(Color.textMuted)
    }
    .safeAreaInset(edge: .bottom) {
        MatchbookTabBar(
            items: [
                MatchbookTabItem(title: "Album", systemImage: "photo.on.rectangle", selectedSystemImage: "photo.on.rectangle.fill"),
                MatchbookTabItem(title: "Career", systemImage: "trophy", selectedSystemImage: "trophy.fill"),
                MatchbookTabItem(title: "Profile", systemImage: "person.crop.circle", selectedSystemImage: "person.crop.circle.fill")
            ],
            selection: $selection
        )
    }
}
