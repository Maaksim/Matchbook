import Foundation
import SwiftData

@MainActor
protocol PlayerRepository {
    func fetchAll() async throws -> [Player]
    func create(_ player: Player) async throws
    func update(_ player: Player) async throws
    func delete(_ player: Player) async throws
}

@MainActor
final class SwiftDataPlayerRepository: PlayerRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [Player] {
        try modelContext.fetch(FetchDescriptor(sortBy: [SortDescriptor(\Player.createdAt)]))
    }

    func create(_ player: Player) async throws {
        modelContext.insert(player)
        try modelContext.save()
    }

    func update(_ player: Player) async throws {
        try modelContext.save()
    }

    func delete(_ player: Player) async throws {
        modelContext.delete(player)
        try modelContext.save()
    }
}
