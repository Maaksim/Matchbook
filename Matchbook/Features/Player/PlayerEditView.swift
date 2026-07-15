import PhotosUI
import SwiftUI

/// The child-profile form, presented as a native sheet by `PlayerCoordinator` for both
/// creating and editing a `Player`. All form state lives in `PlayerEditViewModel` — the only
/// state this View owns is presentational (keyboard focus, whether the delete confirmation is
/// up). It never dismisses itself: "Скасувати", a successful save, and a confirmed delete all
/// just call the ViewModel, which reports back to the Coordinator.
struct PlayerEditView: View {
    @Bindable var viewModel: PlayerEditViewModel

    @FocusState private var focusedField: Field?
    @State private var isConfirmingDelete = false

    private enum Field: Hashable {
        case name, shirtNumber, club
    }

    var body: some View {
        ZStack {
            Color.sheetBackground
                .ignoresSafeArea()
            scrollViewContent
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
        }
        .task(id: viewModel.photoItem) {
            await viewModel.loadPickedPhoto()
        }
        .alert(deleteConfirmationTitle,
               isPresented: $isConfirmingDelete) {
            deleteAlertConfirmButton
            deleteAlertCancelButton
        }
        .alert("error_title_key", isPresented: isShowingError) {
            errorAlertOkButton
        } message: {
            errorMessageText
        }
    }
}

// MARK: - UI components
extension PlayerEditView {
    private var scrollViewContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                avatarPicker
                fieldsCard
                positionSection
                detailsSection
                deleteButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Alerts
extension PlayerEditView {
    private var deleteAlertConfirmButton: some View {
        Button("player_delete_confirm_action_key", role: .destructive) {
            Task { await viewModel.delete() }
        }
    }

    private var deleteAlertCancelButton: some View {
        Button("cancel_key", role: .cancel) {
            print("Delete popup cancelled")
        }

    }

    private var errorAlertOkButton: some View {
        Button("ok_key") {
            viewModel.dismissError()
        }
    }

    @ViewBuilder
    private var errorMessageText: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
        }
    }
}

// MARK: - Header
extension PlayerEditView {
    /// Title centered independently of the two actions, so a long localized title doesn't push
    /// them around (`HStack` + `Spacer` would center it between the buttons, not in the sheet).
    private var header: some View {
        Text(viewModel.title)
            .font(.display(size: 17))
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                cancelButton
            }
            .overlay(alignment: .trailing) {
                saveButton
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 16)
            .background(Color.sheetBackground)
    }

    private var cancelButton: some View {
        Button("cancel_key") { viewModel.cancel() }
            .font(.ui(size: 16))
            .foregroundStyle(Color.textMuted)
    }

    private var saveButton: some View {
        Button(viewModel.saveActionTitle) {
            Task { await viewModel.save() }
        }
        .font(.ui(size: 16, weight: .semibold))
        .foregroundStyle(viewModel.canSave ? Color.brandGreen : Color.textPlaceholder)
        .disabled(!viewModel.canSave)
    }
}

// MARK: - Avatar
extension PlayerEditView {
    private var avatarPicker: some View {
        VStack(spacing: 8) {
            photoPicker
            avatarBottomText
        }
    }

    private var photoPicker: some View {
        // `PhotosPicker`'s label closure is `@Sendable`, so reaching back into this
        // main-actor-isolated View from inside it is a concurrency violation. Read the photo
        // out here and let the closure capture the `Data` (which *is* Sendable) instead.
        let avatarData = viewModel.avatarData

        return PhotosPicker(selection: $viewModel.photoItem, matching: .images, photoLibrary: .shared()) {
            AvatarThumbnail(avatarData: avatarData)
        }
        .accessibilityLabel(Text("player_avatar_accessibility_key"))
    }

    private var avatarBottomText: some View {
        Text("player_add_photo_key")
            .font(.ui(size: 13))
            .foregroundStyle(Color.textMuted)
    }
}

// MARK: - Fields
extension PlayerEditView {
    private var fieldsCard: some View {
        VStack(spacing: 0) {
            nameField
            divider
            numberField
            divider
            clubField
        }
        .cardStyle()
    }

    private var nameField: some View {
        fieldRow(
            label: "player_field_name_key",
            prompt: "player_name_prompt_key",
            text: $viewModel.name,
            field: .name
        )
        .submitLabel(.next)
        .onSubmit { focusedField = .shirtNumber }
    }

    private var numberField: some View {
        fieldRow(
            label: "player_field_number_key",
            prompt: "player_optional_key",
            text: $viewModel.shirtNumberText,
            field: .shirtNumber
        )
        .keyboardType(.numberPad)
    }

    private var clubField: some View {
        fieldRow(
            label: "player_field_club_key",
            prompt: "player_optional_key",
            text: $viewModel.club,
            field: .club
        )
        .submitLabel(.done)
        .onSubmit { focusedField = nil }
    }

    private func fieldRow(
        label: LocalizedStringResource,
        prompt: LocalizedStringResource,
        text: Binding<String>,
        field: Field
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.ui(size: 15))
                .foregroundStyle(Color.textPrimary)

            TextField(String(localized: label), text: text, prompt: promptText(prompt))
                .font(.ui(size: 15))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: field)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }

    /// A `TextField` prompt takes a styled `Text`, so the placeholder color comes from the
    /// design system rather than the system default.
    private func promptText(_ prompt: LocalizedStringResource) -> Text {
        Text(prompt)
            .font(.ui(size: 15))
            .foregroundStyle(Color.textPlaceholder)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(height: 1)
            .padding(.leading, 16)
    }
}

// MARK: - Position
extension PlayerEditView {
    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("player_section_position_key")

            Menu {
                ForEach(PlayerPosition.allCases, id: \.self) { position in
                    Button {
                        viewModel.position = position
                    } label: {
                        Text(position.title)
                    }
                }
            } label: {
                chevronRow(label: nil,
                           value: Text(viewModel.positionLabel),
                           isPlaceholder: !viewModel.hasPosition)
            }
        }
    }

    private func chevronRow(label: LocalizedStringResource?, value: Text, isPlaceholder: Bool) -> some View {
        HStack(spacing: 12) {
            if let label {
                Text(label)
                    .font(.ui(size: 15))
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer(minLength: 0)

            value
                .font(.ui(size: 15))
                .foregroundStyle(isPlaceholder ? Color.textPlaceholder : Color.textPrimary)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textPlaceholder)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .contentShape(Rectangle())
        .cardStyle()
    }
}

// MARK: - Details
extension PlayerEditView {
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("player_section_details_key")

            HStack(spacing: 12) {
                Text("player_field_birth_date_key")
                    .font(.ui(size: 15))
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 0)

                if viewModel.birthDate == nil {
                    // Optional field: nothing is committed until the parent opts in, and the
                    // clear button below puts it back to "not set".
                    Button("player_choose_key") {
                        viewModel.birthDate = viewModel.defaultBirthDate
                    }
                    .font(.ui(size: 15))
                    .foregroundStyle(Color.textPlaceholder)
                } else {
                    // Formatted by the system, never hand-built — uk and en order the
                    // day/month/year differently (Localization.swift, rule 3).
                    DatePicker(
                        String(localized: "player_field_birth_date_key"),
                        selection: birthDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .labelsHidden()

                    Button {
                        viewModel.birthDate = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.textPlaceholder)
                    }
                    .accessibilityLabel(Text("player_clear_birth_date_accessibility_key"))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .cardStyle()
        }
    }

    /// `DatePicker` needs a non-optional `Date`; "not set" is modeled by the ViewModel's
    /// `birthDate == nil` and handled by the branch above, so this only ever runs once a date
    /// exists.
    private var birthDate: Binding<Date> {
        Binding(
            get: { viewModel.birthDate ?? viewModel.defaultBirthDate },
            set: { viewModel.birthDate = $0 }
        )
    }
}

// MARK: - Delete
extension PlayerEditView {
    @ViewBuilder
    private var deleteButton: some View {
        if viewModel.isEditing {
            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Text("player_delete_key")
                    .font(.ui(size: 15, weight: .semibold))
                    .foregroundStyle(Color.destructive)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .cardStyle()
            .disabled(viewModel.isDeleting)
        }
    }

    private var deleteConfirmationTitle: Text {
        guard let message = viewModel.deleteConfirmationMessage else {
            return Text(verbatim: "")
        }

        return Text(message)
    }
}

// MARK: - Shared bits
extension PlayerEditView {
    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.dismissError() }
            }
        )
    }

    private func sectionLabel(_ key: LocalizedStringResource) -> some View {
        Text(key)
            .font(.ui(size: 12, weight: .semibold))
            .foregroundStyle(Color.textMuted)
            .padding(.leading, 4)
    }
}

#Preview("Create") {
    PlayerEditView(
        viewModel: PlayerEditViewModel(
            mode: .create,
            repository: PreviewPlayerRepository()
        )
    )
}

#Preview("Edit") {
    PlayerEditView(
        viewModel: PlayerEditViewModel(
            mode: .edit(previewPlayer()),
            repository: PreviewPlayerRepository()
        )
    )
}

private func previewPlayer() -> Player {
    let player = Player(name: "Марко")
    player.shirtNumber = 10
    player.club = "Динамо"
    player.position = .forward
    return player
}

/// Previews render the form without a SwiftData container behind it.
@MainActor
private final class PreviewPlayerRepository: PlayerRepository {
    func fetchAll() async throws -> [Player] { [] }
    func create(_ player: Player) async throws { }
    func update(_ player: Player) async throws { }
    func delete(_ player: Player) async throws { }
}
