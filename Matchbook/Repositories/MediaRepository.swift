import Foundation
import SwiftData

@MainActor
protocol MediaRepository {
    /// `owner` is `.tournament`/`.match`; compresses before saving.
    func addPhoto(_ data: Data, to owner: MediaOwner) async throws
    func delete(_ item: MediaItem) async throws
}

@MainActor
final class SwiftDataMediaRepository: MediaRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func addPhoto(_ data: Data, to owner: MediaOwner) async throws {
        let item = MediaItem(data: data, isVideo: false)
        switch owner {
        case .tournament(let tournament):
            item.tournament = tournament
        case .match(let match):
            item.match = match
        }
        modelContext.insert(item)
        try modelContext.save()
    }

    func delete(_ item: MediaItem) async throws {
        modelContext.delete(item)
        try modelContext.save()
    }
}
