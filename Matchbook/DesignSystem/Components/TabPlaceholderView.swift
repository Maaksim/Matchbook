import SwiftUI

/// Placeholder shown by the Турніри/Профіль tabs until their real screens are built. Shared
/// so the two tab coordinators don't each carry an identical private copy.
struct TabPlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            Color.screenBackground.ignoresSafeArea()
            Text(title)
                .font(.display(size: 22))
                .foregroundStyle(Color.textPrimary)
        }
        .navigationTitle(title)
    }
}

#Preview {
    TabPlaceholderView(title: "Турніри")
}
