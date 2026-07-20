import SwiftUI
import UIKit

/// Assembles the child-profile form into a `UIHostingController`. The ViewModel is built by
/// `PlayerCoordinator` (which wires its callbacks) and handed in here — how the resulting
/// controller is *presented* is the Coordinator's decision, not the Builder's.
enum PlayerEditBuilder {
    @MainActor
    static func make(viewModel: PlayerEditViewModel) -> UIViewController {
        UIHostingController(rootView: PlayerEditView(viewModel: viewModel))
    }
}
