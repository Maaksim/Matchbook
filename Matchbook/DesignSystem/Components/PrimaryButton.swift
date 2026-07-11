import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(size: 17, weight: .semibold, relativeTo: .body))
            .foregroundStyle(Color.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.brandGreen)
            .clipShape(.rect(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

#Preview("PrimaryButton") {
    VStack(spacing: 16) {
        Button("Save Tournament") { }
            .buttonStyle(.primary)

        Button("Add Match") { }
            .buttonStyle(.primary)
    }
    .padding(24)
    .background(Color.screenBackground)
}
