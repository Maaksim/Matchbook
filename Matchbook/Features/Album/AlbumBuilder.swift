import SwiftUI
import UIKit

/// Builds the Альбом tab's home screen for the active child. `repositories` is threaded in
/// now so WP4's `AlbumHomeViewModel` can be constructed here without changing the call site.
enum AlbumBuilder {
    @MainActor
    static func makeHome(player: Player,
                         repositories: Repositories) -> UIViewController {
        UIHostingController(rootView: AlbumHomeView(player: player))
    }
}
