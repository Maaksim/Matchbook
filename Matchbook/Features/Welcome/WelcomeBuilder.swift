import SwiftUI
import UIKit

/// Builds the Welcome (no-children) stage, wiring its single "add child" action back to the
/// caller (`AppCoordinator`).
enum WelcomeBuilder {
    @MainActor
    static func make(onAddChild: @escaping () -> Void) -> UIViewController {
        UIHostingController(rootView: WelcomeView(onAddChild: onAddChild))
    }
}
