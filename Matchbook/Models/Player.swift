import Foundation
import SwiftData

enum PlayerPosition: String, Codable, CaseIterable {
    case goalkeeper, defender, midfielder, forward, unknown

    var title: LocalizedStringResource {
        switch self {
        case .goalkeeper: "Воротар"
        case .defender:   "Захисник"
        case .midfielder: "Півзахисник"
        case .forward:    "Нападник"
        case .unknown:    "—"
        }
    }
}

@Model
final class Player {
    var id: UUID = UUID()
    var name: String = ""
    @Attribute(.externalStorage) var avatarData: Data?
    var shirtNumber: Int?
    var position: PlayerPosition = PlayerPosition.unknown
    var club: String?
    var birthDate: Date?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Tournament.player)
    var tournaments: [Tournament]? = []

    init(name: String = "") { self.name = name }

    // Career aggregates — computed, not stored
    var allMatches: [Match] { (tournaments ?? []).flatMap { $0.matches ?? [] } }
    var totalTournaments: Int { (tournaments ?? []).count }
    var totalMatches: Int { allMatches.count }
    var totalGoals: Int { allMatches.reduce(0) { $0 + $1.goals } }
    var totalAssists: Int { allMatches.reduce(0) { $0 + $1.assists } }
    var podiums: Int { (tournaments ?? []).filter { ($0.finalPlacement ?? 99) <= 3 }.count }
}
