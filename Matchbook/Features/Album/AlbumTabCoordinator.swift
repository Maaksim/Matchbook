import UIKit

/// Owns the Альбом tab. For WP1 it shows the album home for the already-resolved active
/// child; the tournament/match push flow (`TournamentCoordinator`, `MatchCoordinator`) that
/// hangs off it per the nav map arrives in later packages (WP4+). Because the no-child case
/// is handled by `AppCoordinator`'s Welcome stage before the tab bar ever appears, this
/// coordinator always has a real `Player`.
///
/// WP3 adds the entry point into that child's profile — the edit/delete sheet, presented over
/// this tab by a `PlayerCoordinator`.
@MainActor
final class AlbumTabCoordinator: Coordinator {
    let navigationController: UINavigationController

    /// Forwarded up to `AppCoordinator` (via `MainTabBarCoordinator`) when the active child is
    /// deleted, since that invalidates the whole tab bar.
    var onActivePlayerChanged: ((Player?) -> Void)?

    private let repositories: Repositories
    private let player: Player
    private var playerCoordinator: PlayerCoordinator?

    init(navigationController: UINavigationController,
         repositories: Repositories,
         player: Player) {
        self.navigationController = navigationController
        self.repositories = repositories
        self.player = player
    }

    func start() {
        let home = AlbumBuilder.makeHome(
            player: player,
            repositories: repositories,
            onEditPlayer: { [weak self] in self?.editPlayer() }
        )
        navigationController.setViewControllers([home], animated: false)
    }

    /// A save writes through to the same `Player` instance the home screen is rendering, and
    /// `@Model` types are `@Observable`, so an edited name or photo shows up on its own. Only a
    /// *delete* is escalated — the tab bar is built around one child and has to be rebuilt (or
    /// torn down for the Welcome stage) around whoever is active next.
    private func editPlayer() {
        let coordinator = PlayerCoordinator(presenter: navigationController,
                                            repositories: repositories)
        coordinator.onDeleted = { [weak self] nextPlayer in
            self?.onActivePlayerChanged?(nextPlayer)
        }
        playerCoordinator = coordinator
        coordinator.presentEdit(player)
    }
}
