import Foundation
import Observation
import PhotosUI
import SwiftUI

/// Owns the whole child-profile form — for both creating a new `Player` and editing an
/// existing one — and is the only thing that talks to `PlayerRepository`. `PlayerEditView`
/// binds to this and calls its methods; it never reaches for the repository or the
/// `modelContext` itself.
///
/// Outcomes are reported upward through `onCancel` / `onSaved` / `onDeleted`, which
/// `PlayerCoordinator` sets when it presents the sheet. The ViewModel never dismisses itself
/// and never decides where the app goes next — that's the Coordinator's job (tech doc §2.1).
@Observable
@MainActor
final class PlayerEditViewModel {
    /// Which `Player` the form is editing, if any. `.create` builds a fresh one on save.
    enum Mode {
        case create
        case edit(Player)
    }

    // MARK: - Form state

    var name: String = ""

    /// Kept as text because the field is optional — an empty string means "no number", which
    /// an `Int` can't represent. Non-digits are dropped as they're typed (the numeric keypad
    /// still admits paste), and the value is capped at three digits.
    var shirtNumberText: String = "" {
        didSet {
            let digits = String(shirtNumberText.filter(\.isNumber).prefix(3))
            if digits != shirtNumberText { shirtNumberText = digits }
        }
    }

    var club: String = ""
    var position: PlayerPosition = .unknown
    var birthDate: Date?

    /// Bound to the `PhotosPicker`. The View observes it and calls `loadPickedPhoto()`; the
    /// picked image is compressed before it ever reaches `avatarData`.
    var photoItem: PhotosPickerItem?

    private(set) var avatarData: Data?
    private(set) var isSaving = false
    private(set) var isDeleting = false
    private(set) var errorMessage: LocalizedStringResource?

    // MARK: - Coordinator callbacks
    var onCancel: (() -> Void)?
    var onSaved: ((Player) -> Void)?
    var onDeleted: (() -> Void)?

    private let mode: Mode
    private let repository: PlayerRepository

    init(mode: Mode, repository: PlayerRepository) {
        self.mode = mode
        self.repository = repository

        if case .edit(let player) = mode {
            setupInitData(with: player)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var title: LocalizedStringResource {
        isEditing ? "player_edit_title_key" : "player_new_title_key"
    }

    var saveActionTitle: LocalizedStringResource {
        isEditing ? "player_save_action_key" : "player_add_action_key"
    }

    /// The name is the only required field; everything else can be filled in later.
    var canSave: Bool {
        !trimmedName.isEmpty && !isSaving && !isDeleting
    }

    /// `.unknown` doubles as "not chosen yet" — the row shows a prompt rather than the
    /// position's own "—" title until the parent actually picks one.
    var positionLabel: LocalizedStringResource {
        position == .unknown ? "player_choose_key" : position.title
    }

    var hasPosition: Bool { position != .unknown }

    /// Default landing date for the birth-date picker: mid-range for this app's 6–14 age band,
    /// so the parent scrolls a little rather than a decade.
    var defaultBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -10, to: .now) ?? .now
    }

    /// Spells out the blast radius before anything is deleted: the child, their tournaments,
    /// and every photo hanging off those tournaments and their matches (all of it cascades).
    /// The name passes through as typed — user-generated content is never localized, which
    /// also means it can't be declined into Ukrainian's accusative case ("Видалити Марко …",
    /// not "Марка"); no localization API can decline an arbitrary proper noun.
    var deleteConfirmationMessage: LocalizedStringResource? {
        guard case .edit(let player) = mode else { return nil }
        let tournaments = String(localized: Counts.tournaments(player.totalTournaments))
        let photos = String(localized: Counts.photos(Self.mediaCount(of: player)))
        return LocalizedStringResource(
            "player_delete_confirm_message_key",
            defaultValue: "Видалити \(player.name) та \(tournaments), \(photos)? Це незворотно."
        )
    }

    // MARK: - Actions
    func cancel() {
        onCancel?()
    }

    func dismissError() {
        errorMessage = nil
    }

    /// Loads the `PhotosPicker` selection and compresses it. A nil selection is ignored rather
    /// than treated as "clear the photo" — the View calls this on appear too, and an existing
    /// avatar must survive that.
    func loadPickedPhoto() async {
        guard let photoItem else { return }
        guard let original = try? await photoItem.loadTransferable(type: Data.self) else { return }
        avatarData = await Self.compressedAvatar(from: original)
    }

    func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            switch mode {
            case .create:
                let player = Player(name: trimmedName)
                apply(to: player)
                try await repository.create(player)
                onSaved?(player)
            case .edit(let player):
                apply(to: player)
                try await repository.update(player)
                onSaved?(player)
            }
        } catch {
            errorMessage = "player_save_error_key"
        }
    }

    /// Deletes the child. Every tournament, match, photo and goal-moment underneath goes with
    /// them via the model's `.cascade` delete rules — hence the confirmation above.
    func delete() async {
        guard case .edit(let player) = mode, !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await repository.delete(player)
            onDeleted?()
        } catch {
            errorMessage = "player_delete_error_key"
        }
    }

    // MARK: - Private
    private func setupInitData(with player: Player) {
        name = player.name
        shirtNumberText = player.shirtNumber.map(String.init) ?? ""
        club = player.club ?? ""
        position = player.position
        birthDate = player.birthDate
        avatarData = player.avatarData
    }

    private func apply(to player: Player) {
        let trimmedClub = club.trimmingCharacters(in: .whitespacesAndNewlines)

        player.name = trimmedName
        player.shirtNumber = Int(shirtNumberText)
        player.club = trimmedClub.isEmpty ? nil : trimmedClub
        player.position = position
        player.birthDate = birthDate
        player.avatarData = avatarData
    }

    private static func mediaCount(of player: Player) -> Int {
        (player.tournaments ?? []).reduce(0) { total, tournament in
            let matchMedia = (tournament.matches ?? []).reduce(0) { $0 + ($1.media?.count ?? 0) }
            return total + (tournament.media?.count ?? 0) + matchMedia
        }
    }

    /// An avatar is never displayed larger than ~96pt, so storing the picker's full-resolution
    /// original would put megabytes into the store for nothing (and, once WP13 turns sync on,
    /// push them through CloudKit). Downscale to 512px on the long edge and JPEG-encode.
    ///
    /// Runs off the main actor: `Data` in, `Data` out, with the `UIImage` created and consumed
    /// entirely inside the closure, so nothing non-`Sendable` crosses the boundary.
    private nonisolated static func compressedAvatar(from data: Data) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: data) else { return nil }

            let maxDimension: CGFloat = 512
            let longEdge = max(image.size.width, image.size.height)
            let scale = min(1, maxDimension / max(longEdge, 1))
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)

            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            return resized.jpegData(compressionQuality: 0.8)
        }.value
    }
}
