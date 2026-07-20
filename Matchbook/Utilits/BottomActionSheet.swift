import SwiftUI

/// One row of a `bottomActionSheet`.
struct ActionSheetButton {
    let title: LocalizedStringResource
    var role: ButtonRole?
    let action: () -> Void
}

extension View {
    /// Presents `buttons` in a bottom-anchored action sheet styled with the design system.
    ///
    /// SwiftUI's `confirmationDialog` and UIKit's `UIAlertController(.actionSheet)` both render as
    /// a floating, centred card on iOS 26 when shown over a page sheet — neither sits at the bottom
    /// edge — so this is a hand-rolled overlay that always pins to the bottom. Being a plain SwiftUI
    /// overlay (no `.sheet`/`.confirmationDialog`) it also hands off cleanly to the follow-up camera
    /// / library pickers, with no UIKit "already presenting" race.
    func bottomActionSheet(
        isPresented: Binding<Bool>,
        title: LocalizedStringResource,
        buttons: [ActionSheetButton]
    ) -> some View {
        modifier(BottomActionSheet(isPresented: isPresented,
                                   title: title,
                                   buttons: buttons))
    }
}

struct BottomActionSheet: ViewModifier {
    @Binding var isPresented: Bool

    let title: LocalizedStringResource
    let buttons: [ActionSheetButton]

    func body(content: Content) -> some View {
        content.overlay {
            ZStack(alignment: .bottom) {
                if isPresented {
                    scrim
                    sheet
                }
            }
            .animation(.easeInOut(duration: 0.25),
                       value: isPresented)
        }
    }

    private var scrim: some View {
        // Tap-outside-to-dismiss. Hidden from VoiceOver — the sheet's own Cancel row is the
        // accessible way out, so the scrim would just be a second, unlabeled "dismiss" target.
        Button { dismiss(nil) } label: {
            Color.black.opacity(0.35)
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .transition(.opacity)
        .accessibilityHidden(true)
    }

    private var sheet: some View {
        VStack(spacing: 8) {
            actionCard
            cancelCard
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom))
    }

    private var actionCard: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.ui(size: 13))
                .foregroundStyle(Color.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)

            ForEach(Array(actionButtons.enumerated()), id: \.offset) { _, button in
                Rectangle()
                    .fill(Color.hairline)
                    .frame(height: 1)
                row(button, weight: .regular)
            }
        }
        .background(Color.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
    }

    @ViewBuilder
    private var cancelCard: some View {
        if let cancel = buttons.first(where: { $0.role == .cancel }) {
            row(cancel, weight: .semibold)
                .background(Color.cardSurface)
                .clipShape(.rect(cornerRadius: 14))
        }
    }

    private func row(_ button: ActionSheetButton, weight: Font.Weight) -> some View {
        Button {
            dismiss(button.action)
        } label: {
            Text(button.title)
                .font(.ui(size: 17, weight: weight))
                .foregroundStyle(button.role == .destructive ? Color.destructive : Color.brandGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(Rectangle())
        }
    }

    private var actionButtons: [ActionSheetButton] {
        buttons.filter { $0.role != .cancel }
    }

    /// Closes the sheet, then runs the tapped row's action. The follow-up (open camera / library)
    /// runs after the closing animation so it starts from a settled state.
    private func dismiss(_ action: (() -> Void)?) {
        isPresented = false
        guard let action else { return }
        Task { @MainActor in action() }
    }
}
