import Foundation
import SwiftData

@Model
final class MediaItem {
    var id: UUID = UUID()
    @Attribute(.externalStorage) var data: Data?  // large payloads live outside the DB
    var isVideo: Bool = false
    var caption: String?
    var createdAt: Date = Date()

    var tournament: Tournament?
    var match: Match?

    init(data: Data? = nil, isVideo: Bool = false) {
        self.data = data
        self.isVideo = isVideo
    }
}

/// Which parent a photo/video is being attached to — `MediaRepository.addPhoto(_:to:)`
/// takes this instead of two separate methods so callers can't set both/neither relationship.
enum MediaOwner {
    case tournament(Tournament)
    case match(Match)
}
