import SwiftData
import SwiftUI

@main
struct MatchbookApp: App {
    var body: some Scene {
        WindowGroup {
            // RootCoordinatorHost wraps a UIViewControllerRepresentable that creates the
            // RootCoordinator (see Coordinators/), calls start(), and returns its
            // UITabBarController — MVVM+C's UIKit navigation root, bridged into the
            // SwiftUI App lifecycle for a single entry point.
            RootCoordinatorHost()
        }
        .modelContainer(for: [Player.self, Tournament.self, Match.self,
                               MediaItem.self, GoalMoment.self])
        // For sync: the iCloud + CloudKit capability must be enabled on the app target
        // (Matchbook.entitlements + Signing & Capabilities) — SwiftData then mirrors to
        // the private database automatically. This syncs a single Apple ID's own devices
        // only; it does NOT make a child's profile visible to a different Apple ID — that
        // requires a separate CKShare-based family-sharing feature, out of scope until
        // Phase 2 (WP13).
    }
}
