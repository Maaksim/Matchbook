import SwiftUI
import UIKit

/// Minimal stand-in for the Профіль tab until WP9/WP10 build the real profile screen here.
@MainActor
final class ProfileTabCoordinator: Coordinator {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let view = TabPlaceholderView(title: "tab_profile_key")
        navigationController.setViewControllers([UIHostingController(rootView: view)], animated: false)
    }
}
