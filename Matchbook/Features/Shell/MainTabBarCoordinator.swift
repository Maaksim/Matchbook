import UIKit

/// Owns the root `UITabBarController` (Альбом / Турніри / Профіль) and constructs one `UINavigationController` + concrete tab `Coordinator` per tab.
@MainActor
final class MainTabBarCoordinator {
    let tabBarController = UITabBarController()

    private let repositories: Repositories
    private let activePlayer: Player
    private var childCoordinators: [Coordinator] = []

    init(repositories: Repositories, activePlayer: Player) {
        self.repositories = repositories
        self.activePlayer = activePlayer
    }

    func start() {
        // UITabBarItem takes a plain String, so the catalog is resolved eagerly here via
        // String(localized:) rather than passed along as a LocalizedStringResource.
        let albumNavigationController = UINavigationController()
        albumNavigationController.tabBarItem = UITabBarItem(
            title: String(localized: "tab_album_key"),
            image: UIImage(resource: .iconTabAlbum),
            tag: 0
        )

        let tournamentsNavigationController = UINavigationController()
        tournamentsNavigationController.tabBarItem = UITabBarItem(
            title: String(localized: "tab_tournaments_key"),
            image: UIImage(resource: .iconTabTournament),
            tag: 1
        )

        let profileNavigationController = UINavigationController()
        profileNavigationController.tabBarItem = UITabBarItem(
            title: String(localized: "tab_profile_key"),
            image: UIImage(resource: .iconTabProfile),
            tag: 2
        )

        tabBarController.viewControllers = [
            albumNavigationController,
            tournamentsNavigationController,
            profileNavigationController,
        ]

        let albumCoordinator = AlbumTabCoordinator(
            navigationController: albumNavigationController,
            repositories: repositories,
            player: activePlayer
        )
        let tournamentsCoordinator = TournamentsTabCoordinator(navigationController: tournamentsNavigationController)
        let profileCoordinator = ProfileTabCoordinator(navigationController: profileNavigationController)

        childCoordinators = [albumCoordinator, tournamentsCoordinator, profileCoordinator]
        childCoordinators.forEach { $0.start() }
    }
}
