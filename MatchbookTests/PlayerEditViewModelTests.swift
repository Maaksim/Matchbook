import Foundation
import SwiftData
import Testing
@testable import Matchbook

@MainActor
struct PlayerEditViewModelTests {
    // Retained so the in-memory store outlives the models created against it — see the note
    // in MatchRepositoryTests. Without it the container deallocs after init() and the context
    // resets ("ModelContext.reset" crash on iOS 26).
    private let container: ModelContainer
    private let repository: SwiftDataPlayerRepository

    init() throws {
        container = try ModelContainer(
            for: Player.self, Tournament.self, Match.self, MediaItem.self, GoalMoment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        repository = SwiftDataPlayerRepository(modelContext: container.mainContext)
    }

    // MARK: - Create
    @Test
    func createPersistsTheFormAndReportsTheNewPlayer() async throws {
        let viewModel = PlayerEditViewModel(mode: .create, repository: repository)
        var savedPlayer: Player?
        viewModel.onSaved = { savedPlayer = $0 }

        viewModel.name = "  Марко  "
        viewModel.shirtNumberText = "10"
        viewModel.club = "Динамо"
        viewModel.position = .forward
        viewModel.birthDate = Date(timeIntervalSince1970: 0)

        await viewModel.save()

        let players = try await repository.fetchAll()
        #expect(players.count == 1)

        let player = try #require(players.first)
        // The name is trimmed on the way in; everything else is stored as entered.
        #expect(player.name == "Марко")
        #expect(player.shirtNumber == 10)
        #expect(player.club == "Динамо")
        #expect(player.position == .forward)
        #expect(player.birthDate == Date(timeIntervalSince1970: 0))
        #expect(savedPlayer?.id == player.id)
    }

    @Test
    func createLeavesOptionalFieldsNil() async throws {
        let viewModel = PlayerEditViewModel(mode: .create, repository: repository)
        viewModel.name = "Марко"
        // Number and club left blank, position untouched, no photo picked.

        await viewModel.save()

        let player = try #require(try await repository.fetchAll().first)
        #expect(player.shirtNumber == nil)
        #expect(player.club == nil)
        #expect(player.birthDate == nil)
        #expect(player.avatarData == nil)
        #expect(player.position == .unknown)
    }

    @Test
    func blankClubIsStoredAsNilNotAnEmptyString() async throws {
        let viewModel = PlayerEditViewModel(mode: .create, repository: repository)
        viewModel.name = "Марко"
        viewModel.club = "   "

        await viewModel.save()

        let player = try #require(try await repository.fetchAll().first)
        #expect(player.club == nil)
    }

    // MARK: - Validation

    @Test
    func cannotSaveUntilTheNameIsNonEmpty() {
        let viewModel = PlayerEditViewModel(mode: .create, repository: repository)
        #expect(!viewModel.canSave)

        viewModel.name = "   "
        #expect(!viewModel.canSave, "whitespace alone is not a name")

        viewModel.name = "Марко"
        #expect(viewModel.canSave)
    }

    @Test
    func savingWithABlankNameIsANoOp() async throws {
        let viewModel = PlayerEditViewModel(mode: .create, repository: repository)
        viewModel.name = " "

        await viewModel.save()

        #expect(try await repository.fetchAll().isEmpty)
    }

    @Test(arguments: [
        ("abc", ""),
        ("1a0", "10"),
        ("10", "10"),
        ("1234", "123"),
    ])
    func shirtNumberKeepsOnlyUpToThreeDigits(typed: String, expected: String) {
        let viewModel = PlayerEditViewModel(mode: .create, repository: repository)
        viewModel.shirtNumberText = typed
        #expect(viewModel.shirtNumberText == expected)
    }

    // MARK: - Edit

    @Test
    func editPrefillsTheFormFromTheExistingPlayer() async throws {
        let player = Player(name: "Марко")
        player.shirtNumber = 7
        player.club = "Динамо"
        player.position = .midfielder
        player.birthDate = Date(timeIntervalSince1970: 0)
        try await repository.create(player)

        let viewModel = PlayerEditViewModel(mode: .edit(player), repository: repository)

        #expect(viewModel.isEditing)
        #expect(viewModel.name == "Марко")
        #expect(viewModel.shirtNumberText == "7")
        #expect(viewModel.club == "Динамо")
        #expect(viewModel.position == .midfielder)
        #expect(viewModel.birthDate == Date(timeIntervalSince1970: 0))
        #expect(viewModel.canSave, "a prefilled form is immediately saveable")
    }

    @Test
    func editUpdatesInPlaceWithoutCreatingASecondPlayer() async throws {
        let player = Player(name: "Марко")
        player.shirtNumber = 7
        try await repository.create(player)

        let viewModel = PlayerEditViewModel(mode: .edit(player), repository: repository)
        viewModel.name = "Марко Б."
        viewModel.shirtNumberText = ""
        viewModel.position = .goalkeeper

        await viewModel.save()

        let players = try await repository.fetchAll()
        #expect(players.count == 1)
        #expect(players.first?.id == player.id)
        #expect(players.first?.name == "Марко Б.")
        #expect(players.first?.shirtNumber == nil, "clearing the field clears the stored number")
        #expect(players.first?.position == .goalkeeper)
    }

    // MARK: - Delete

    @Test
    func deleteRemovesThePlayerAndReportsIt() async throws {
        let player = Player(name: "Марко")
        try await repository.create(player)

        let viewModel = PlayerEditViewModel(mode: .edit(player), repository: repository)
        var didReportDeletion = false
        viewModel.onDeleted = { didReportDeletion = true }

        await viewModel.delete()

        #expect(didReportDeletion)
        #expect(try await repository.fetchAll().isEmpty)
    }

    @Test
    func deleteIsUnavailableWhenCreating() async throws {
        let viewModel = PlayerEditViewModel(mode: .create, repository: repository)
        var didReportDeletion = false
        viewModel.onDeleted = { didReportDeletion = true }

        await viewModel.delete()

        #expect(!didReportDeletion)
        #expect(viewModel.deleteConfirmationMessage == nil)
    }

    /// The confirmation has to name the blast radius before anything cascades: the child, their
    /// tournaments, and every photo hanging off those tournaments *and* their matches.
    @Test
    func deleteConfirmationCountsTournamentsAndPhotosAcrossMatches() async throws {
        let player = Player(name: "Марко")
        let tournament = Tournament(name: "Кубок")
        let match = Match(opponent: "Шахтар")

        tournament.media = [MediaItem(), MediaItem()]
        match.media = [MediaItem()]
        tournament.matches = [match]
        player.tournaments = [tournament]
        try await repository.create(player)

        let viewModel = PlayerEditViewModel(mode: .edit(player), repository: repository)
        let message = String(localized: try #require(viewModel.deleteConfirmationMessage))

        // 1 tournament, and 3 photos — 2 on the tournament plus 1 on its match.
        //
        // The counts are resolved through `Counts` rather than spelled out, because the copy
        // this assertion sees depends on the language the test process happens to run in.
        // Pinning the actual Ukrainian and English plural forms is `LocalizationTests`' job;
        // what matters here is that the message embeds the *right numbers*, whatever the
        // language. The name is asserted literally — user-generated content is never localized,
        // so it reads the same in every locale.
        #expect(message.contains("Марко"))
        #expect(message.contains(String(localized: Counts.tournaments(1))))
        #expect(message.contains(String(localized: Counts.photos(3))))
    }

    // MARK: - Failure handling

    @Test
    func aFailedSaveSurfacesAnErrorInsteadOfReportingSuccess() async {
        let viewModel = PlayerEditViewModel(mode: .create, repository: FailingPlayerRepository())
        var savedPlayer: Player?
        viewModel.onSaved = { savedPlayer = $0 }
        viewModel.name = "Марко"

        await viewModel.save()

        #expect(savedPlayer == nil, "a failed write must not tell the Coordinator to dismiss")
        #expect(viewModel.errorMessage != nil)

        viewModel.dismissError()
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func aFailedDeleteSurfacesAnErrorInsteadOfReportingSuccess() async {
        let viewModel = PlayerEditViewModel(mode: .edit(Player(name: "Марко")),
                                            repository: FailingPlayerRepository())
        var didReportDeletion = false
        viewModel.onDeleted = { didReportDeletion = true }

        await viewModel.delete()

        #expect(!didReportDeletion)
        #expect(viewModel.errorMessage != nil)
    }
}

/// Every write fails — used to pin the ViewModel's error paths, which a real (in-memory)
/// repository won't exercise.
@MainActor
private final class FailingPlayerRepository: PlayerRepository {
    private struct WriteFailure: Error { }

    func fetchAll() async throws -> [Player] { [] }
    func create(_ player: Player) async throws { throw WriteFailure() }
    func update(_ player: Player) async throws { throw WriteFailure() }
    func delete(_ player: Player) async throws { throw WriteFailure() }
}
