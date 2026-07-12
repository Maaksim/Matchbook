import SwiftUI

/// Full-bleed brand moment shown on cold launch. `AppCoordinator` swaps this out after ~1s
/// once the launch destination has resolved.
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.brandGreen.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 96, height: 96)
                    Text("М")
                        .font(.display(size: 40))
                        .foregroundStyle(Color.white)
                }

                VStack(spacing: 6) {
                    Text("Матчбук")
                        .font(.display(size: 28))
                        .foregroundStyle(Color.white)
                    Text("Турніри, які не забудуться")
                        .font(.ui(size: 15))
                        .foregroundStyle(Color.white.opacity(0.85))
                }

                Spacer()

                Text("дитячий футбол · спогади")
                    .font(.ui(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    SplashView()
}
