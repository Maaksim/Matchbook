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
                // A semantic key with an argument can't be a bare `Text("key")` — the
                // interpolation has to ride on `defaultValue`, which supplies %@ while the
                // shipped copy still comes from the catalog. `player.name` is user-entered
                // and passes through untranslated.
                Text(LocalizedStringResource("album_greeting_key", defaultValue: "Вітаємо, \(player.name)!"))
                    .font(.display(size: 24))
                    .foregroundStyle(Color.textPrimary)
                Text("album_home_placeholder_key")
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
