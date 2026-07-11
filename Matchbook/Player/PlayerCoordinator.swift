import SwiftUI
import UIKit

/// Fully implemented for WP1: routes Splash → Empty/Syncing/placeholder-Home. The
/// tournament/match push flow (`TournamentCoordinator`, `MatchCoordinator`) that hangs off
/// `PlayerHomeView` per the nav map belongs to later packages (WP4+).
@MainActor
final class PlayerCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let repositories: Repositories
    private let launchViewModel: LaunchViewModel

    init(navigationController: UINavigationController, repositories: Repositories) {
        self.navigationController = navigationController
        self.repositories = repositories
        self.launchViewModel = LaunchViewModel(repository: repositories.player)
    }

    func start() {
        launchViewModel.onAddChild = { [weak self] in
            self?.showAddChild()
        }

        // Splash is a full-bleed brand moment — hide the tab bar chrome behind it for the
        // ~1s it's on screen, then restore it once we land on Empty/Syncing/Home.
        navigationController.tabBarController?.tabBar.isHidden = true
        navigationController.setViewControllers([UIHostingController(rootView: SplashView())], animated: false)

        Task { [weak self] in
            guard let self else { return }
            let destination = await launchViewModel.resolveDestination()
            try? await Task.sleep(for: .seconds(1))
            show(destination)
        }
    }

    private func show(_ destination: LaunchViewModel.Destination) {
        let hostingController: UIViewController
        switch destination {
        case .empty:
            hostingController = UIHostingController(rootView: EmptyStateView(viewModel: launchViewModel))
        case .syncing:
            hostingController = UIHostingController(rootView: SyncingView())
        case .home(let player):
            hostingController = UIHostingController(
                rootView: PlaceholderHomeView(viewModel: launchViewModel, player: player)
            )
        }
        navigationController.setViewControllers([hostingController], animated: true)
        navigationController.tabBarController?.tabBar.isHidden = false
    }

    private func showAddChild() {
        // PlayerEditView doesn't exist until WP3 — wired here once it does.
        print("PlayerCoordinator: onAddChild tapped (PlayerEditView arrives in WP3)")
    }
}
