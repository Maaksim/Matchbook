import SwiftUI

/// Circular brandGreen "+" FAB paired with an adjacent pill label naming the action.
/// The label and the "+" glyph are a single `Button` so VoiceOver treats them as one
/// control announcing the action name, not two disconnected elements.
struct FloatingActionPill: View {
    let actionName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 56, height: 56)
                .background(Color.brandGreen)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(actionName)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("FloatingActionPill") {
    ZStack {
        Color.screenBackground.ignoresSafeArea()
    }
    .overlay(alignment: .bottomTrailing) {
        FloatingActionPill(actionName: "Add Match") { }
            .padding(24)
    }
}
