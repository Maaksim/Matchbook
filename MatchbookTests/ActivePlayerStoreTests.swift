import Foundation
import Testing
@testable import Matchbook

/// Serialized because every test here writes the one `activePlayerID` key the whole app shares
/// (`LaunchViewModelTests` does the same for the same reason).
@MainActor
@Suite(.serialized)
struct ActivePlayerStoreTests {
    init() {
        UserDefaults.standard.removeObject(forKey: ActivePlayerStore.key)
    }

    @Test
    func roundTripsThroughUserDefaults() {
        let id = UUID()
        ActivePlayerStore.id = id

        #expect(ActivePlayerStore.id == id)
        #expect(UserDefaults.standard.string(forKey: ActivePlayerStore.key) == id.uuidString)
    }

    /// Clearing the pointer is what routes the app back to the Welcome stage after the last
    /// child is deleted — it has to actually remove the key, not store an empty string.
    @Test
    func clearingRemovesTheKey() {
        ActivePlayerStore.id = UUID()
        ActivePlayerStore.id = nil

        #expect(ActivePlayerStore.id == nil)
        #expect(UserDefaults.standard.object(forKey: ActivePlayerStore.key) == nil)
    }

    @Test
    func garbageValueReadsAsNoSelection() {
        UserDefaults.standard.set("not-a-uuid", forKey: ActivePlayerStore.key)
        #expect(ActivePlayerStore.id == nil)
    }
}
