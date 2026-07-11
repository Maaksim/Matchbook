import SwiftData
import SwiftUI

/// Placeholder for the "players exist" launch destination — replaced by the real
/// `PlayerHomeView` in WP4.
struct PlaceholderHomeView: View {
    let viewModel: LaunchViewModel
    let player: Player

    var body: some View {
        ZStack {
            Color.screenBackground.ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Вітаємо, \(player.name)!")
                    .font(.display(size: 24))
                    .foregroundStyle(Color.textPrimary)
                Text("Домашній екран з'явиться в наступному пакеті.")
                    .font(.ui(size: 14))
                    .foregroundStyle(Color.textMuted)
            }
            .padding(24)
        }
        .safeAreaInset(edge: .top) {
            if viewModel.showICloudBanner {
                ICloudUnavailableBanner(onDismiss: viewModel.dismissICloudBanner)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Player.self, Tournament.self, Match.self, MediaItem.self, GoalMoment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let player = Player(name: "Марко")
    return PlaceholderHomeView(
        viewModel: LaunchViewModel(repository: SwiftDataPlayerRepository(modelContext: container.mainContext)),
        player: player
    )
}
