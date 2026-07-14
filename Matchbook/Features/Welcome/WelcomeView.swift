import SwiftUI

/// Shown as a full-screen stage by `AppCoordinator` when there's no child yet — before the
/// tab bar exists. The "add child" button calls back to the coordinator (child creation is WP3).
struct WelcomeView: View {
    let onAddChild: () -> Void

    var body: some View {
        ZStack {
            Color.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .center, spacing: 0) {
                imageView
                textBlock
                featureRowsScrollContainer
                addChildButton
            }
            .padding(.top, 50)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - UI components
extension WelcomeView {
    private var imageView: some View {
        Image(.welcomeBackgroundIcon)
            .resizable()
            .frame(width: 140, height: 140)
    }

    private var textBlock: some View {
        VStack(alignment: .center, spacing: 6) {
            Text("welcome_title_key")
                .font(.display(size: 26))
                .foregroundStyle(Color.textPrimary)
            Text("welcome_subtitle_key")
                .font(.ui(size: 15))
                .foregroundStyle(Color.textMuted)
        }
        .padding(.top, 25)
    }


    private var featureRowsScrollContainer: some View {
        ScrollView {
            featureRows
        }
        .padding(.vertical, 24)
    }

    private var featureRows: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(imageText: "🏆", text: "welcome_feature_album_key")
            FeatureRow(imageText: "🖼️", text: "welcome_feature_photos_key")
            FeatureRow(imageText: "↗", text: "welcome_feature_cards_key")
        }
    }

    private var addChildButton: some View {
        Button("add_child_key", action: onAddChild)
            .buttonStyle(.primary)
            .padding(.vertical, 20)
    }
}

private struct FeatureRow: View {
    /// Decorative emoji — not localized, and hidden from VoiceOver by the row's own label.
    let imageText: String
    let text: LocalizedStringResource

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Rectangle()
                    .fill(Color.chipTint)
                    .cornerRadius(8)
                Text(imageText)
                    .foregroundStyle(Color.brandGreen)
            }
            .frame(width: 32, height: 32)

            Text(text)
                .font(.ui(size: 14))
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    WelcomeView(onAddChild: {})
}
