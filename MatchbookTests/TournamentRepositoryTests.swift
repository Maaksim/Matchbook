import Foundation
import SwiftData
import Testing
@testable import Matchbook

@MainActor
struct TournamentRepositoryTests {
    private let repository: SwiftDataTournamentRepository
    private let player: Player

    init() throws {
        let container = try ModelContainer(
            for: Player.self, Tournament.self, Match.self, MediaItem.self, GoalMoment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let modelContext = container.mainContext
        repository = SwiftDataTournamentRepository(modelContext: modelContext)
        player = Player(name: "Марко")
        modelContext.insert(player)
    }

    @Test
    func createAndFetchAll() async throws {
        let tournament = Tournament(name: "Кубок Карпат")
        try await repository.create(tournament, for: player)

        let tournaments = try await repository.fetchAll(for: player)
        #expect(tournaments.count == 1)
        #expect(tournaments.first?.name == "Кубок Карпат")
        #expect(tournaments.first?.player === player)
    }

    @Test
    func update() async throws {
        let tournament = Tournament(name: "Кубок Карпат")
        try await repository.create(tournament, for: player)

        tournament.name = "Кубок Львова"
        try await repository.update(tournament)

        let tournaments = try await repository.fetchAll(for: player)
        #expect(tournaments.first?.name == "Кубок Львова")
    }

    @Test
    func delete() async throws {
        let tournament = Tournament(name: "Кубок Карпат")
        try await repository.create(tournament, for: player)
        try await repository.delete(tournament)

        let tournaments = try await repository.fetchAll(for: player)
        #expect(tournaments.isEmpty)
    }

    @Test
    func canCreateTournamentWithinFreeLimit() async throws {
        #expect(repository.canCreateTournament(for: player, isSubscribed: false) == true)

        try await repository.create(Tournament(name: "One"), for: player)
        #expect(repository.canCreateTournament(for: player, isSubscribed: false) == true)
    }

    @Test
    func canCreateTournamentAtFreeLimit() async throws {
        try await repository.create(Tournament(name: "One"), for: player)
        try await repository.create(Tournament(name: "Two"), for: player)

        #expect(repository.canCreateTournament(for: player, isSubscribed: false) == false)
        #expect(repository.canCreateTournament(for: player, isSubscribed: true) == true)
    }
}
