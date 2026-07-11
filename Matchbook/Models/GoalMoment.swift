import Foundation
import SwiftData

// Phase 2 — per-goal detail. Model exists now so `Match.moments` can declare its
// inverse relationship; UI comes in WP13.
enum GoalKind: String, Codable, CaseIterable {
    case openPlay, penalty, freeKick, header, other
}

@Model
final class GoalMoment {
    var id: UUID = UUID()
    var isAssist: Bool = false   // false = goal, true = assist
    var kind: GoalKind = GoalKind.openPlay
    var minute: Int?
    var note: String?
    var match: Match?
    init() {}
}
