import Foundation
import SwiftData

@MainActor
protocol TournamentRepository {
    func fetchAll(for player: Player) async throws -> [Tournament]
    func create(_ tournament: Tournament, for player: Player) async throws
    func update(_ tournament: Tournament) async throws
    func delete(_ tournament: Tournament) async throws   // cascades to Match/MediaItem
    func canCreateTournament(for player: Player, isSubscribed: Bool) -> Bool // paywall gate lives here, not in the View
}

/// Free tier per the monetization spec: 1–2 tournaments in full.
private let freeTierTournamentLimit = 2

@MainActor
final class SwiftDataTournamentRepository: TournamentRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll(for player: Player) async throws -> [Tournament] {
        (player.tournaments ?? []).sorted { $0.startDate > $1.startDate }
    }

    func create(_ tournament: Tournament, for player: Player) async throws {
        tournament.player = player
        modelContext.insert(tournament)
        try modelContext.save()
    }

    func update(_ tournament: Tournament) async throws {
        try modelContext.save()
    }

    func delete(_ tournament: Tournament) async throws {
        modelContext.delete(tournament)
        try modelContext.save()
    }

    func canCreateTournament(for player: Player, isSubscribed: Bool) -> Bool {
        isSubscribed || player.totalTournaments < freeTierTournamentLimit
    }
}
