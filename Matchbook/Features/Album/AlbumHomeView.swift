import SwiftUI

/// Placeholder for the Альбом tab's home screen — replaced by the real album/home UI in WP4.
/// Always receives the resolved active child (the no-child case is handled upstream by the
/// Welcome stage), so it takes a plain `Player`.
///
/// The "edit child" button is a stand-in too: WP3's edit/delete sheet needs an entry point and
/// the real one (the hero header, per tech doc §4.3) doesn't exist until WP4. WP4 replaces the
/// button, not the `onEditPlayer` wiring behind it.
struct AlbumHomeView: View {
    let player: Player
    let onEditPlayer: () -> Void

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

                Button("album_edit_child_key", action: onEditPlayer)
                    .buttonStyle(.primary)
                    .padding(.top, 24)
            }
            .padding(24)
        }
    }
}

#Preview {
    AlbumHomeView(player: Player(name: "Марко"), onEditPlayer: {})
}
