import SwiftUI

/// One-time, dismissible, non-blocking banner shown when the device has no iCloud account
/// configured. Never blocks any flow — the app must be fully usable without iCloud.
struct ICloudUnavailableBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "icloud.slash")
                .foregroundStyle(Color.textPrimary)

            Text("Дані зберігаються тільки на цьому пристрої — увімкни iCloud, щоб не втратити їх при заміні телефону.")
                .font(.ui(size: 13))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(Color.textMuted)
            }
            .accessibilityLabel("Закрити")
        }
        .padding(16)
        .background(Color.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    ZStack {
        Color.screenBackground.ignoresSafeArea()
        VStack {
            ICloudUnavailableBanner(onDismiss: {})
            Spacer()
        }
    }
}
