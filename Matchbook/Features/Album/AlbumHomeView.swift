import SwiftUI

/// Placeholder for the Альбом tab's home screen — replaced by the real album/home UI in WP4.
/// Always receives the resolved active child (the no-child case is handled upstream by the
/// Welcome stage), so it takes a plain `Player`.
struct AlbumHomeView: View {
    let player: Player

    var body: some View {
        ZStack {
            Color.screenBackground.ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Вітаємо, \(player.name)!")
                    .font(.display(size: 24))
                    .foregroundStyle(Color.textPrimary)
                Text("Домашній екран з'явиться в наступному пакеті.")
                    .font(.ui(size: 14))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(24)
        }
    }
}

#Preview {
    AlbumHomeView(player: Player(name: "Марко"))
}
