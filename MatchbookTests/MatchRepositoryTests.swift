import Foundation
import SwiftData
import Testing
@testable import Matchbook

@MainActor
struct MatchRepositoryTests {
    private let repository: SwiftDataMatchRepository
    private let tournament: Tournament

    init() throws {
        let container = try ModelContainer(
            for: Player.self, Tournament.self, Match.self, MediaItem.self, GoalMoment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let modelContext = container.mainContext
        repository = SwiftDataMatchRepository(modelContext: modelContext)
        tournament = Tournament(name: "Кубок Карпат")
        modelContext.insert(tournament)
    }

    @Test
    func create() async throws {
        let match = Match(opponent: "Динамо U-11")
        try await repository.create(match, for: tournament)

        #expect(match.tournament === tournament)
        #expect(tournament.matches?.count == 1)
    }

    @Test
    func update() async throws {
        let match = Match(opponent: "Динамо U-11")
        try await repository.create(match, for: tournament)

        match.teamScore = 3
        match.opponentScore = 1
        try await repository.update(match)

        #expect(match.outcome == .win)
        #expect(match.scoreLine == "3:1")
    }

    @Test
    func delete() async throws {
        let match = Match(opponent: "Динамо U-11")
        try await repository.create(match, for: tournament)
        try await repository.delete(match)

        #expect(tournament.matches?.isEmpty == true)
    }
}
