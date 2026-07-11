import Foundation
import SwiftData

enum MatchOutcome: String, Codable {
    case win, draw, loss
}

@Model
final class Match {
    var id: UUID = UUID()
    var date: Date = Date()
    var opponent: String = ""
    var teamScore: Int = 0
    var opponentScore: Int = 0
    var stage: String?          // "Group A", "1/4", "Final"
    var goals: Int = 0          // child's goals — simple counter, MVP only
    var assists: Int = 0        // child's assists
    var minutesPlayed: Int?
    var playerRating: Double?   // 0…10, optional
    var isMotm: Bool = false    // Man of the Match
    var notes: String?
    var createdAt: Date = Date()

    var tournament: Tournament?

    @Relationship(deleteRule: .cascade, inverse: \MediaItem.match)
    var media: [MediaItem]? = []

    // Phase 2: replace goals/assists counters with a list of moments
    @Relationship(deleteRule: .cascade, inverse: \GoalMoment.match)
    var moments: [GoalMoment]? = []

    init(opponent: String = "", date: Date = Date()) {
        self.opponent = opponent
        self.date = date
    }

    var outcome: MatchOutcome {
        if teamScore > opponentScore { return .win }
        if teamScore < opponentScore { return .loss }
        return .draw
    }
    var scoreLine: String { "\(teamScore):\(opponentScore)" }
}
