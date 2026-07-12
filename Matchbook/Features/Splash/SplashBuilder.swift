import SwiftUI
import UIKit

/// Builds the Splash stage. Kept as a builder like the other feature modules so the
/// construction seam is uniform, even though the Splash has no ViewModel.
enum SplashBuilder {
    @MainActor
    static func make() -> UIViewController {
        UIHostingController(rootView: SplashView())
    }
}
