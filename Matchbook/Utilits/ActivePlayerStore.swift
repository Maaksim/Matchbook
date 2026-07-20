import Foundation

/// The single owner of the `activePlayerID` user-defaults key — which child the app is
/// currently scoped to. Read at launch by `LaunchViewModel`, rewritten by `PlayerCoordinator`
/// when a child is created or the active child is deleted. Keeping the raw key in one place is
/// the point: it's read and written from two different layers.
///
/// A computed static (no stored global state) so Swift 6 strict concurrency is satisfied
/// without isolating it — `UserDefaults` is already thread-safe.
enum ActivePlayerStore {
    static let key = "activePlayerID"

    static var id: UUID? {
        get {
            UserDefaults.standard.string(forKey: key).flatMap(UUID.init(uuidString:))
        }
        set {
            guard let newValue else {
                UserDefaults.standard.removeObject(forKey: key)
                return
            }
            UserDefaults.standard.set(newValue.uuidString, forKey: key)
        }
    }
}
