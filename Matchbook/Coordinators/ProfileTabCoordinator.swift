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
        let view = TabPlaceholderView(title: "Профіль")
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
