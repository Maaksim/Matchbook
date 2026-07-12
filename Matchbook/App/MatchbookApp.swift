import SwiftData
import SwiftUI

@main
struct MatchbookApp: App {
    // CloudKit sync is deliberately off for now — it needs a paid Apple Developer account
    // to provision a real iCloud container, which isn't available yet. Re-enabling is WP13
    // (Matchbook-AI-Work-Packages.md): restore the two keys in Matchbook.entitlements,
    // complete Signing & Capabilities in Xcode, and flip cloudKitDatabase back to .automatic
    // (or drop this explicit container and go back to the plain `.modelContainer(for:)`
    // convenience modifier, which defaults to `.automatic`).
    private let modelContainer: ModelContainer = {
        let schema = Schema([Player.self, Tournament.self, Match.self, MediaItem.self, GoalMoment.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        return try! ModelContainer(for: schema, configurations: configuration)
    }()

    var body: some Scene {
        WindowGroup {
            // AppCoordinatorHost wraps a UIViewControllerRepresentable that creates the
            // AppCoordinator (see App/), calls start(), and returns its root
            // ContainerViewController — MVVM+C's UIKit navigation root, bridged into the
            // SwiftUI App lifecycle for a single entry point. The AppCoordinator shows the
            // Splash and (if there's no child yet) Welcome as full-screen stages before the
            // MainTabBarCoordinator's tab bar ever appears.
            AppCoordinatorHost()
        }
        .modelContainer(modelContainer)
    }
}
