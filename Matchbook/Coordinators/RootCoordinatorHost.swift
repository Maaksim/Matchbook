import SwiftUI

/// The only place the SwiftUI `App`/`Scene` lifecycle touches the UIKit Coordinator tree:
/// builds the `RootCoordinator` from the environment's `ModelContext`, starts it, and hosts
/// its `UITabBarController`.
///
/// Deliberately never spells out the bare type `Coordinator` in this file — the app already
/// has a top-level `Coordinator` protocol, and `UIViewControllerRepresentable` has its own
/// `associatedtype Coordinator`. Returning the concrete `RootCoordinator` type from
/// `makeCoordinator()` lets Swift infer that associated type without ever naming it directly.
struct RootCoordinatorHost: UIViewControllerRepresentable {
    @Environment(\.modelContext) private var modelContext

    func makeCoordinator() -> RootCoordinator {
        RootCoordinator(repositories: Repositories(modelContext: modelContext))
    }

    func makeUIViewController(context: Context) -> UITabBarController {
        context.coordinator.start()
        return context.coordinator.tabBarController
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {}
}
