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
        let albumNavigationController = UINavigationController()
        albumNavigationController.tabBarItem = UITabBarItem(
            title: "Альбом",
            image: UIImage(resource: .iconTabAlbum),
            tag: 0
        )

        let tournamentsNavigationController = UINavigationController()
        tournamentsNavigationController.tabBarItem = UITabBarItem(
            title: "Турніри",
            image: UIImage(resource: .iconTabTournament),
            tag: 1
        )

        let profileNavigationController = UINavigationController()
        profileNavigationController.tabBarItem = UITabBarItem(
            title: "Профіль",
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
