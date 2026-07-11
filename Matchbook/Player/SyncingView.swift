import SwiftUI

/// Lightweight, non-blocking indicator shown instead of the Empty State when the CloudKit
/// account suggests this could be a second device still catching up on sync.
struct SyncingView: View {
    var body: some View {
        ZStack {
            Color.screenBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color.brandGreen)
                Text("Синхронізуємо дані з iCloud…")
                    .font(.ui(size: 15))
                    .foregroundStyle(Color.textMuted)
            }
        }
    }
}

#Preview {
    SyncingView()
}
