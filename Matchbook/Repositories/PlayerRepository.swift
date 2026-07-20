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
        try saveOrRollback()
    }

    func update(_ player: Player) async throws {
        try saveOrRollback()
    }

    func delete(_ player: Player) async throws {
        modelContext.delete(player)
        try saveOrRollback()
    }

    /// The `mainContext` is shared and autosaving, and callers mutate the live `@Model` *before*
    /// calling here, so a failed `save()` would otherwise leave those rejected changes sitting
    /// dirty in the context — visible in the UI and flushed by the next (auto)save. Roll back to
    /// the last persisted state before rethrowing so a failure is a true no-op.
    private func saveOrRollback() throws {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
