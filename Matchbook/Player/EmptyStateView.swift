import SwiftData
import SwiftUI

struct EmptyStateView: View {
    let viewModel: LaunchViewModel

    var body: some View {
        ZStack {
            Color.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        coverTile
                        textBlock
                        featureRows
                    }
                    .padding(24)
                }

                Button("＋ Додати дитину", action: viewModel.addChild)
                    .buttonStyle(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
            }
        }
        .safeAreaInset(edge: .top) {
            if viewModel.showICloudBanner {
                ICloudUnavailableBanner(onDismiss: viewModel.dismissICloudBanner)
            }
        }
    }
}

// MARK: - UI components
extension EmptyStateView {
    private var coverTile: some View {
        ZStack {
            PhotoPlaceholder(caption: "")
            Text("⚽️")
                .font(.system(size: 40))
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: 20))
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Вітаємо в Матчбуці")
                .font(.display(size: 26))
                .foregroundStyle(Color.textPrimary)
            Text("Створюйте фотоальбом кожного турніру дитини — з голами, місцями й спогадами, які не загубляться.")
                .font(.ui(size: 15))
                .foregroundStyle(Color.textMuted)
        }
    }

    private var featureRows: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(systemImage: "trophy.fill", text: "Турнір — окремий альбом, не дашборд")
            FeatureRow(systemImage: "photo.fill", text: "Фото на першому плані")
            FeatureRow(systemImage: "square.and.arrow.up.fill", text: "Картки для чатів команди й сторіз")
        }
    }
}

private struct FeatureRow: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.chipTint)
                Image(systemName: systemImage)
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
    let container = try! ModelContainer(
        for: Player.self, Tournament.self, Match.self, MediaItem.self, GoalMoment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return EmptyStateView(viewModel: LaunchViewModel(repository: SwiftDataPlayerRepository(modelContext: container.mainContext)))
}
