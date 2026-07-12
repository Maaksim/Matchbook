import UIKit

/// Owns the Альбом tab. For WP1 it shows the album home for the already-resolved active
/// child; the tournament/match push flow (`TournamentCoordinator`, `MatchCoordinator`) that
/// hangs off it per the nav map arrives in later packages (WP4+). Because the no-child case
/// is handled by `AppCoordinator`'s Welcome stage before the tab bar ever appears, this
/// coordinator always has a real `Player`.
@MainActor
final class AlbumTabCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let repositories: Repositories
    private let player: Player

    init(navigationController: UINavigationController,
         repositories: Repositories,
         player: Player) {
        self.navigationController = navigationController
        self.repositories = repositories
        self.player = player
    }

    func start() {
        let home = AlbumBuilder.makeHome(player: player, repositories: repositories)
        navigationController.setViewControllers([home], animated: false)
    }
}
