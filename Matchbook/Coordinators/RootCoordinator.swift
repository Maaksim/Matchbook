import UIKit

/// Owns the root `UITabBarController` (Альбом / Турніри / Профіль) and constructs one
/// `UINavigationController` + concrete `Coordinator` per tab. This is the one coordinator
/// that doesn't itself conform to `Coordinator` — it owns a tab bar, not a single nav stack.
@MainActor
final class RootCoordinator {
    let tabBarController = UITabBarController()

    private let repositories: Repositories
    private var childCoordinators: [Coordinator] = []

    init(repositories: Repositories) {
        self.repositories = repositories
    }

    func start() {
        let playerNavigationController = UINavigationController()
        playerNavigationController.tabBarItem = UITabBarItem(
            title: "Альбом", image: UIImage(resource: .iconTabAlbum), tag: 0
        )

        let tournamentsNavigationController = UINavigationController()
        tournamentsNavigationController.tabBarItem = UITabBarItem(
            title: "Турніри", image: UIImage(resource: .iconTabTournament), tag: 1
        )

        let profileNavigationController = UINavigationController()
        profileNavigationController.tabBarItem = UITabBarItem(
            title: "Профіль", image: UIImage(resource: .iconTabProfile), tag: 2
        )

        // Assign the tab controllers before starting their coordinators, so each
        // navigationController.tabBarController back-reference already resolves
        // (PlayerCoordinator uses it to hide the tab bar behind the full-bleed Splash).
        tabBarController.viewControllers = [
            playerNavigationController, tournamentsNavigationController, profileNavigationController,
        ]

        let playerCoordinator = PlayerCoordinator(
            navigationController: playerNavigationController, repositories: repositories
        )
        let tournamentsCoordinator = TournamentsTabCoordinator(navigationController: tournamentsNavigationController)
        let profileCoordinator = ProfileTabCoordinator(navigationController: profileNavigationController)

        childCoordinators = [playerCoordinator, tournamentsCoordinator, profileCoordinator]
        childCoordinators.forEach { $0.start() }
    }
}
