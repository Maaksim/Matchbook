import SwiftUI
import UIKit

/// Minimal stand-in for the Турніри tab until a later package builds a real tournament list
/// here. Named apart from the future push-flow `TournamentCoordinator` (owned by the Альбом
/// tab's flow, WP4+) to avoid a type collision once that's added.
@MainActor
final class TournamentsTabCoordinator: Coordinator {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let view = TabPlaceholderView(title: "Турніри")
        navigationController.setViewControllers([UIHostingController(rootView: view)], animated: false)
    }
}

private struct TabPlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            Color.screenBackground.ignoresSafeArea()
            Text(title)
                .font(.display(size: 22))
                .foregroundStyle(Color.textPrimary)
        }
        .navigationTitle(title)
    }
}
