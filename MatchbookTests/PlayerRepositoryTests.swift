import Foundation
import SwiftData
import Testing
@testable import Matchbook

@MainActor
struct PlayerRepositoryTests {
    private let repository: SwiftDataPlayerRepository

    init() throws {
        let container = try ModelContainer(
            for: Player.self, Tournament.self, Match.self, MediaItem.self, GoalMoment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        repository = SwiftDataPlayerRepository(modelContext: container.mainContext)
    }

    @Test
    func createAndFetchAll() async throws {
        let player = Player(name: "Марко")
        try await repository.create(player)

        let players = try await repository.fetchAll()
        #expect(players.count == 1)
        #expect(players.first?.name == "Марко")
    }

    @Test
    func fetchAllSortedByCreatedAt() async throws {
        let first = Player(name: "First")
        first.createdAt = Date(timeIntervalSince1970: 0)
        let second = Player(name: "Second")
        second.createdAt = Date(timeIntervalSince1970: 1000)

        try await repository.create(second)
        try await repository.create(first)

        let players = try await repository.fetchAll()
        #expect(players.map(\.name) == ["First", "Second"])
    }

    @Test
    func update() async throws {
        let player = Player(name: "Марко")
        try await repository.create(player)

        player.name = "Максим"
        try await repository.update(player)

        let players = try await repository.fetchAll()
        #expect(players.first?.name == "Максим")
    }

    @Test
    func delete() async throws {
        let player = Player(name: "Марко")
        try await repository.create(player)
        try await repository.delete(player)

        let players = try await repository.fetchAll()
        #expect(players.isEmpty)
    }
}
