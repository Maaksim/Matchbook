import Foundation
import Observation
import SwiftUI

/// Resolves the launch-time routing decision (Splash → Empty/Home) for `AppCoordinator`:
/// reads the persisted players and the active-child selection, with no UI state of its own.
@Observable
@MainActor
final class LaunchViewModel {
    enum Destination {
        case empty
        case home(Player)
    }

    @ObservationIgnored
    @AppStorage("activePlayerID") private var activePlayerIDString: String = ""

    private let repository: PlayerRepository

    init(repository: PlayerRepository) {
        self.repository = repository
    }

    func resolveDestination() async -> Destination {
        let players = (try? await repository.fetchAll()) ?? []

        guard let firstPlayer = players.first else {
            return .empty
        }

        if !players.contains(where: { $0.id.uuidString == activePlayerIDString }) {
            activePlayerIDString = firstPlayer.id.uuidString
        }
        let activePlayer = players.first { $0.id.uuidString == activePlayerIDString } ?? firstPlayer
        return .home(activePlayer)
    }
}
