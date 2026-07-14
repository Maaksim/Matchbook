import Foundation
import SwiftData

enum TournamentFormat: String, Codable, CaseIterable {
    case league             // round robin / groups
    case knockout           // knockout
    case groupPlusKnockout  // groups + knockout
    case friendly           // friendly
    case other

    var title: LocalizedStringResource {
        switch self {
        case .league:             "format_league_key"
        case .knockout:           "format_knockout_key"
        case .groupPlusKnockout:  "format_group_plus_knockout_key"
        case .friendly:           "format_friendly_key"
        case .other:              "format_other_key"
        }
    }
}

@Model
final class Tournament {
    var id: UUID = UUID()
    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date?
    var city: String?
    var venue: String?
    var format: TournamentFormat = TournamentFormat.other
    var teamName: String?          // team the child played for
    var finalPlacement: Int?       // 1, 2, 3… nil if not applicable
    var placementLabel: String?    // "Champions", "Finalists", "Group stage"
    @Attribute(.externalStorage) var coverPhotoData: Data?  // tournament cover image
    var notes: String?
    var createdAt: Date = Date()

    var player: Player?

    @Relationship(deleteRule: .cascade, inverse: \Match.tournament)
    var matches: [Match]? = []
    @Relationship(deleteRule: .cascade, inverse: \MediaItem.tournament)
    var media: [MediaItem]? = []

    init(name: String = "", startDate: Date = Date()) {
        self.name = name
        self.startDate = startDate
    }

    // Tournament aggregates
    var sortedMatches: [Match] { (matches ?? []).sorted { $0.date < $1.date } }
    var goals: Int { (matches ?? []).reduce(0) { $0 + $1.goals } }
    var assists: Int { (matches ?? []).reduce(0) { $0 + $1.assists } }
    var wins: Int { (matches ?? []).filter { $0.outcome == .win }.count }
    var isPodium: Bool { (finalPlacement ?? 99) <= 3 }
}
