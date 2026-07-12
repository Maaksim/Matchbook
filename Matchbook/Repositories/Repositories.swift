import Foundation
import SwiftData

/// Small bag of the four repository protocols, constructed once from the environment's
/// `ModelContext` (see `AppCoordinatorHost`) and threaded down through Coordinator
/// initializers from there on — Views/ViewModels never reach for `modelContext` directly.
struct Repositories {
    let player: PlayerRepository
    let tournament: TournamentRepository
    let match: MatchRepository
    let media: MediaRepository

    @MainActor
    init(modelContext: ModelContext) {
        player = SwiftDataPlayerRepository(modelContext: modelContext)
        tournament = SwiftDataTournamentRepository(modelContext: modelContext)
        match = SwiftDataMatchRepository(modelContext: modelContext)
        media = SwiftDataMediaRepository(modelContext: modelContext)
    }
}
