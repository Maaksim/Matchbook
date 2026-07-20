import Foundation
import Observation

/// Resolves the launch-time routing decision (Splash → Empty/Home) for `AppCoordinator`:
/// reads the persisted players and the active-child selection, with no UI state of its own.
@Observable
@MainActor
final class LaunchViewModel {
    enum Destination {
        case empty
        case home(Player)
    }

    private let repository: PlayerRepository

    init(repository: PlayerRepository) {
        self.repository = repository
    }

    func resolveDestination() async -> Destination {
        let players = (try? await repository.fetchAll()) ?? []

        guard let firstPlayer = players.first else {
            return .empty
        }

        // A stale pointer (the child it named was deleted on another device, say) falls back to
        // the first child and is re-persisted, so the two never disagree after a launch.
        let activePlayer = players.first { $0.id == ActivePlayerStore.id } ?? firstPlayer
        ActivePlayerStore.id = activePlayer.id
        return .home(activePlayer)
    }
}
