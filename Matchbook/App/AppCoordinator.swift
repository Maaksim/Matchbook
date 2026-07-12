import UIKit

/// The app-level flow coordinator and composition root. Owns the window's root
/// `ContainerViewController` and advances the launch flow through full-screen stages:
/// Splash → Welcome (no children yet) or the main tab bar (a child already exists). Splash
/// and Welcome are shown *before* / *instead of* the tab bar, not as states inside it.
///
/// Like `MainTabBarCoordinator`, it owns a container rather than a single navigation stack,
/// so it deliberately doesn't conform to the `Coordinator` protocol (which requires a
/// `navigationController`).
@MainActor
final class AppCoordinator {
    let rootViewController = ContainerViewController()

    private let repositories: Repositories
    private let launchViewModel: LaunchViewModel
    private var mainTabBarCoordinator: MainTabBarCoordinator?

    /// Keeps the Splash up for at least this long so a fast launch still reads as an
    /// intentional brand moment rather than a flash.
    private let minimumSplashDuration: Duration = .seconds(1)

    init(repositories: Repositories) {
        self.repositories = repositories
        self.launchViewModel = LaunchViewModel(repository: repositories.player)
    }

    func start() {
        rootViewController.setContent(SplashBuilder.make(), animated: false)

        Task { [weak self] in
            guard let self else { return }
            // Resolve while the Splash is on screen, then top up to the minimum duration.
            // Sequential await (no `async let`): the `.home` payload is a non-Sendable
            // @Model that must stay on the main actor (see CLAUDE.md).
            let clock = ContinuousClock()
            let started = clock.now
            let destination = await launchViewModel.resolveDestination()
            let elapsed = clock.now - started
            if elapsed < minimumSplashDuration {
                try? await Task.sleep(for: minimumSplashDuration - elapsed)
            }
            show(destination)
        }
    }

    private func show(_ destination: LaunchViewModel.Destination) {
        switch destination {
        case .empty:
            let welcome = WelcomeBuilder.make(onAddChild: { [weak self] in self?.addChild() })
            rootViewController.setContent(welcome, animated: true)
        case .home(let player):
            showMainApp(activePlayer: player)
        }
    }

    private func showMainApp(activePlayer: Player) {
        let coordinator = MainTabBarCoordinator(repositories: repositories,
                                                activePlayer: activePlayer)
        coordinator.start()
        mainTabBarCoordinator = coordinator
        rootViewController.setContent(coordinator.tabBarController, animated: true)
    }

    private func addChild() {
        // Welcome's "Додати дитину" — the child-creation flow arrives in WP3. Once it exists,
        // create the Player through repositories.player and then call
        // showMainApp(activePlayer:) to swap the Welcome stage for the main tab bar.
        print("AppCoordinator: onAddChild tapped (child-creation flow arrives in WP3)")
    }
}
