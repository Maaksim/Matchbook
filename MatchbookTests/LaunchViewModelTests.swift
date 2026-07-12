import Foundation
import SwiftData
import Testing
@testable import Matchbook

/// Covers the launch-routing logic `AppCoordinator` depends on. Serialized because the tests
/// share the `activePlayerID` UserDefaults key that `LaunchViewModel` reads/writes.
@MainActor
@Suite(.serialized)
struct LaunchViewModelTests {
    private let repository: SwiftDataPlayerRepository
    private let viewModel: LaunchViewModel
    private let activePlayerKey = "activePlayerID"

    init() throws {
        let container = try ModelContainer(
            for: Player.self, Tournament.self, Match.self, MediaItem.self, GoalMoment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        repository = SwiftDataPlayerRepository(modelContext: container.mainContext)
        viewModel = LaunchViewModel(repository: repository)
        // Clean active-child selection so each test is independent of the others and of the
        // host app's stored value.
        UserDefaults.standard.removeObject(forKey: activePlayerKey)
    }

    @Test
    func resolvesToEmptyWhenNoPlayers() async {
        let destination = await viewModel.resolveDestination()
        guard case .empty = destination else {
            Issue.record("Expected .empty, got \(destination)")
            return
        }
    }

    @Test
    func resolvesToHomeAndPersistsFirstPlayerWhenNoSelection() async throws {
        let player = Player(name: "Марко")
        try await repository.create(player)

        let destination = await viewModel.resolveDestination()
        guard case .home(let resolved) = destination else {
            Issue.record("Expected .home, got \(destination)")
            return
        }
        #expect(resolved.id == player.id)
        // First resolution with no prior selection persists the first player as active.
        #expect(UserDefaults.standard.string(forKey: activePlayerKey) == player.id.uuidString)
    }

    @Test
    func honorsPersistedActivePlayerSelection() async throws {
        let first = Player(name: "First")
        first.createdAt = Date(timeIntervalSince1970: 0)
        let second = Player(name: "Second")
        second.createdAt = Date(timeIntervalSince1970: 1000)
        try await repository.create(first)
        try await repository.create(second)

        // Pre-select the non-first player; resolution must honor it, not default to first.
        UserDefaults.standard.set(second.id.uuidString, forKey: activePlayerKey)

        let destination = await viewModel.resolveDestination()
        guard case .home(let resolved) = destination else {
            Issue.record("Expected .home, got \(destination)")
            return
        }
        #expect(resolved.id == second.id)
    }

    @Test
    func fallsBackToFirstPlayerWhenSelectionUnknown() async throws {
        let player = Player(name: "Марко")
        try await repository.create(player)

        // A stale/unknown id should fall back to the first player and re-persist it.
        UserDefaults.standard.set(UUID().uuidString, forKey: activePlayerKey)

        let destination = await viewModel.resolveDestination()
        guard case .home(let resolved) = destination else {
            Issue.record("Expected .home, got \(destination)")
            return
        }
        #expect(resolved.id == player.id)
        #expect(UserDefaults.standard.string(forKey: activePlayerKey) == player.id.uuidString)
    }
}
