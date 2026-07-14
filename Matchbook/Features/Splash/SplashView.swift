import SwiftUI

/// Full-bleed brand moment shown on cold launch. `AppCoordinator` swaps this out after ~1s
/// once the launch destination has resolved.
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.brandGreen

            VStack(spacing: 0) {
                Spacer()
                imageView
                aboutTextView
                Spacer()
                supportTextView
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - UI components
extension SplashView {
    private var imageView: some View {
        Image(.splashImageView)
            .resizable()
            .frame(width: 200, height: 200)
    }

    private var aboutTextView: some View {
        VStack(spacing: 6) {
            Text("Матчбук")
                .font(.display(size: 28))
                .foregroundStyle(Color.white)
            Text("Турніри, які не забудуться")
                .font(.ui(size: 15))
                .foregroundStyle(Color.white.opacity(0.85))
        }
    }

    private var supportTextView: some View {
        Text("дитячий футбол · спогади")
            .font(.ui(size: 12, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.7))
            .padding(.bottom, 32)
    }
}

#Preview {
    SplashView()
}
