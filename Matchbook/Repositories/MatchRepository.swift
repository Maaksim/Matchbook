import Foundation
import SwiftData

@MainActor
protocol MatchRepository {
    func create(_ match: Match, for tournament: Tournament) async throws
    func update(_ match: Match) async throws
    func delete(_ match: Match) async throws
}

@MainActor
final class SwiftDataMatchRepository: MatchRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(_ match: Match, for tournament: Tournament) async throws {
        match.tournament = tournament
        modelContext.insert(match)
        try modelContext.save()
    }

    func update(_ match: Match) async throws {
        try modelContext.save()
    }

    func delete(_ match: Match) async throws {
        modelContext.delete(match)
        try modelContext.save()
    }
}
