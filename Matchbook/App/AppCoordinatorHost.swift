import SwiftUI

/// The only place the SwiftUI `App`/`Scene` lifecycle touches the UIKit coordinator tree:
/// builds the `AppCoordinator` from the environment's `ModelContext`, starts it, and hosts
/// its root `ContainerViewController`.
///
/// Deliberately never spells out the bare type `Coordinator` in this file — the app has a
/// top-level `Coordinator` protocol, and `UIViewControllerRepresentable` has its own
/// `associatedtype Coordinator`. Returning the concrete `AppCoordinator` from
/// `makeCoordinator()` lets Swift infer that associated type without ever naming it directly.
struct AppCoordinatorHost: UIViewControllerRepresentable {
    @Environment(\.modelContext) private var modelContext

    func makeCoordinator() -> AppCoordinator {
        AppCoordinator(repositories: Repositories(modelContext: modelContext))
    }

    func makeUIViewController(context: Context) -> ContainerViewController {
        context.coordinator.start()
        return context.coordinator.rootViewController
    }

    func updateUIViewController(_ uiViewController: ContainerViewController, context: Context) {}
}
