import CloudKit
import Foundation
import Observation
import SwiftUI

/// Owns the launch-time routing decision (Splash → Empty/Syncing/Home) and the one-time
/// iCloud-unavailable banner. Shared by all three post-splash screens — they're facets of
/// one launch-routing concern, not independent long-lived screens with their own ViewModels.
@Observable
@MainActor
final class LaunchViewModel {
    enum Destination {
        case empty
        case syncing
        case home(Player)
    }

    @ObservationIgnored
    @AppStorage("activePlayerID") private var activePlayerIDString: String = ""

    @ObservationIgnored
    @AppStorage("hasDismissedICloudBanner") private var hasDismissedICloudBanner: Bool = false

    private(set) var showICloudBanner = false

    /// Set by `PlayerCoordinator` — fires when the Empty State's "Додати дитину" button is tapped.
    var onAddChild: (() -> Void)?

    private let repository: PlayerRepository

    init(repository: PlayerRepository) {
        self.repository = repository
    }

    func resolveDestination() async -> Destination {
        let accountStatus = try? await CKContainer.default().accountStatus()
        showICloudBanner = !hasDismissedICloudBanner
            && (accountStatus == .noAccount || accountStatus == .restricted)

        let players = (try? await repository.fetchAll()) ?? []

        guard let firstPlayer = players.first else {
            // No local players yet. An available account suggests this could be a second
            // device still catching up on sync — show Syncing instead of nudging the user
            // into creating a duplicate child.
            return accountStatus == .available ? .syncing : .empty
        }

        if !players.contains(where: { $0.id.uuidString == activePlayerIDString }) {
            activePlayerIDString = firstPlayer.id.uuidString
        }
        let activePlayer = players.first { $0.id.uuidString == activePlayerIDString } ?? firstPlayer
        return .home(activePlayer)
    }

    func dismissICloudBanner() {
        hasDismissedICloudBanner = true
        showICloudBanner = false
    }

    func addChild() {
        onAddChild?()
    }
}
