import SwiftUI

/// Fills its container with a diagonal repeating-stripe pattern in two very light
/// greens, with a small centered monospaced uppercase caption. Used for any empty
/// photo/cover slot (tournament cover, match gallery, avatar) — size is entirely
/// driven by the caller's frame.
struct PhotoPlaceholder: View {
    var caption: LocalizedStringResource = "no_photo_key"

    private let stripeColorA = Color(red: 0xD7 / 255, green: 0xE6 / 255, blue: 0xD2 / 255)
    private let stripeColorB = Color(red: 0xE2 / 255, green: 0xEC / 255, blue: 0xDD / 255)
    private let stripeWidth: CGFloat = 22

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(stripeColorB))

            let diagonal = (size.width + size.height) * 1.5
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: .degrees(45))
            context.translateBy(x: -diagonal / 2, y: -diagonal / 2)

            var x: CGFloat = 0
            while x < diagonal {
                let stripe = Path(CGRect(x: x, y: 0, width: stripeWidth, height: diagonal))
                context.fill(stripe, with: .color(stripeColorA))
                x += stripeWidth * 2
            }
        }
        .clipped()
        .overlay {
            Text(caption)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(Color.textMuted)
        }
    }
}

#Preview("PhotoPlaceholder") {
    VStack(spacing: 16) {
        PhotoPlaceholder(caption: "no_cover_photo_key")
            .frame(height: 160)
            .clipShape(.rect(cornerRadius: 20))

        PhotoPlaceholder(caption: "no_photo_key")
            .frame(width: 100, height: 100)
            .clipShape(.rect(cornerRadius: 13))
    }
    .padding(24)
    .background(Color.screenBackground)
}
