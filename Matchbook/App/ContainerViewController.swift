import UIKit

/// The window's root view controller for the whole app. Hosts exactly one child at a time
/// and swaps it as the launch flow advances (Splash → Welcome, or Splash → the main tab
/// bar), so every stage is a full-screen presentation with no shared chrome — the tab bar
/// only exists once `AppCoordinator` installs the `MainTabBarCoordinator`'s controller here.
@MainActor
final class ContainerViewController: UIViewController {
    private var content: UIViewController?

    /// Swaps the displayed child view controller, cross-dissolving from the previous one
    /// when `animated` is true. Uses standard child-VC containment.
    func setContent(_ newContent: UIViewController, animated: Bool) {
        let previous = content
        content = newContent

        addChild(newContent)
        newContent.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newContent.view)
        NSLayoutConstraint.activate([
            newContent.view.topAnchor.constraint(equalTo: view.topAnchor),
            newContent.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newContent.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newContent.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let finish: () -> Void = {
            newContent.didMove(toParent: self)
            guard let previous else { return }
            previous.willMove(toParent: nil)
            previous.view.removeFromSuperview()
            previous.removeFromParent()
        }

        guard animated, previous != nil else {
            finish()
            return
        }

        newContent.view.alpha = 0
        UIView.animate(
            withDuration: 0.3,
            animations: {
                newContent.view.alpha = 1
                previous?.view.alpha = 0
            },
            completion: { _ in finish() }
        )
    }
}
