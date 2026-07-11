import Foundation
import SwiftData
import Testing
@testable import Matchbook

@MainActor
struct MediaRepositoryTests {
    private let repository: SwiftDataMediaRepository
    private let tournament: Tournament
    private let match: Match

    init() throws {
        let container = try ModelContainer(
            for: Player.self, Tournament.self, Match.self, MediaItem.self, GoalMoment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let modelContext = container.mainContext
        repository = SwiftDataMediaRepository(modelContext: modelContext)
        tournament = Tournament(name: "Кубок Карпат")
        match = Match(opponent: "Динамо U-11")
        modelContext.insert(tournament)
        modelContext.insert(match)
    }

    @Test
    func addPhotoToTournament() async throws {
        let data = Data([0x01, 0x02, 0x03])
        try await repository.addPhoto(data, to: .tournament(tournament))

        #expect(tournament.media?.count == 1)
        #expect(tournament.media?.first?.data == data)
    }

    @Test
    func addPhotoToMatch() async throws {
        let data = Data([0x04, 0x05])
        try await repository.addPhoto(data, to: .match(match))

        #expect(match.media?.count == 1)
    }

    @Test
    func delete() async throws {
        let data = Data([0x01])
        try await repository.addPhoto(data, to: .tournament(tournament))
        let item = try #require(tournament.media?.first)

        try await repository.delete(item)

        #expect(tournament.media?.isEmpty == true)
    }
}
