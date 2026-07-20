import UIKit

/// Owns the child-profile flow — presenting the create/edit sheet and deciding what happens
/// after it reports a save or a delete. The View never dismisses itself and the ViewModel never
/// routes; both hand their outcome here (tech doc §2.1).
///
/// It presents modally over whoever is on screen rather than pushing onto a stack, so — like
/// `AppCoordinator` and `MainTabBarCoordinator` — it deliberately doesn't conform to
/// `Coordinator`, which requires a `navigationController`. It's used from two places: the
/// Welcome stage (create the first child, presented over `AppCoordinator`'s container) and the
/// Альбом tab (edit/delete the active child, presented over the tab's nav controller).
///
/// **Naming, because the docs and the code disagree here:** the tech doc's nav map (§4.8) and
/// the work-packages doc call the *Альбом tab's* coordinator "PlayerCoordinator" — WP1 shipped
/// that one as `AlbumTabCoordinator`, leaving the name free. So when a later package says
/// "`PlayerCoordinator` pushes/presents X from the album home" (WP4's `TournamentEditView`, for
/// one), it means `AlbumTabCoordinator`, not this type. This one owns exactly one thing: the
/// child-profile create/edit/delete sheet.
@MainActor
final class PlayerCoordinator {
    /// The child was created or updated. On create, the active-child pointer has already been
    /// moved to them by the time this fires.
    var onSaved: ((Player) -> Void)?

    /// The child was deleted. The payload is whichever child is active *now* — the next one
    /// remaining, or `nil` when that was the last child and the app has to fall back to the
    /// Welcome stage. The pointer is already updated by the time this fires.
    var onDeleted: ((Player?) -> Void)?

    private let presenter: UIViewController
    private let repositories: Repositories
    private weak var presentedViewController: UIViewController?

    init(presenter: UIViewController, repositories: Repositories) {
        self.presenter = presenter
        self.repositories = repositories
    }

    func presentCreate() {
        present(mode: .create, editedPlayerID: nil)
    }

    func presentEdit(_ player: Player) {
        present(mode: .edit(player), editedPlayerID: player.id)
    }

    // MARK: - Private

    /// `editedPlayerID` is captured up front because it's needed *after* the delete, when the
    /// `Player` object is gone from the context and can't be read anymore.
    private func present(mode: PlayerEditViewModel.Mode, editedPlayerID: UUID?) {
        let viewModel = PlayerEditViewModel(mode: mode, repository: repositories.player)
        let isCreating = editedPlayerID == nil

        viewModel.onCancel = { [weak self] in
            self?.dismiss()
        }
        viewModel.onSaved = { [weak self] player in
            self?.handleSaved(player, isNew: isCreating)
        }
        viewModel.onDeleted = { [weak self] in
            self?.handleDeleted()
        }

        let controller = PlayerEditBuilder.make(viewModel: viewModel)
        controller.modalPresentationStyle = .pageSheet
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        presentedViewController = controller
        presenter.present(controller, animated: true)
    }

    private func handleSaved(_ player: Player, isNew: Bool) {
        // A new child becomes the active one immediately — the app is scoped to one child at a
        // time, and a parent who just added a child expects to land on them.
        if isNew {
            ActivePlayerStore.id = player.id
        }
        dismiss { [weak self] in
            self?.onSaved?(player)
        }
    }

    private func handleDeleted() {
        Task { [weak self] in
            guard let self else { return }

            // Re-resolve the pointer against what's actually left, which covers both cases in
            // one pass: if the deleted child was the active one their id is no longer in the
            // list and we fall through to the first remaining child; if they weren't, the
            // current selection is still there and survives. `nil` means none remain and the
            // pointer is cleared, which routes the app back to the Welcome stage.
            let remaining = (try? await repositories.player.fetchAll()) ?? []
            let currentID = ActivePlayerStore.id
            let next = remaining.first { $0.id == currentID } ?? remaining.first
            ActivePlayerStore.id = next?.id

            dismiss { [weak self] in
                self?.onDeleted?(next)
            }
        }
    }

    /// `completion` runs after the sheet is off screen, so the caller can swap the stage behind
    /// it without fighting the dismissal animation. UIKit always calls back on the main thread.
    private func dismiss(then completion: @escaping @MainActor () -> Void = { }) {
        guard let controller = presentedViewController else {
            completion()
            return
        }
        presentedViewController = nil
        controller.dismiss(animated: true) {
            MainActor.assumeIsolated(completion)
        }
    }
}
