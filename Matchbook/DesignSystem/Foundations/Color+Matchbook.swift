import SwiftUI

extension Color {
    static let brandGreen = Color("brandGreen")
    static let brandGreenSecondary = Color("brandGreenSecondary")

    static let screenBackground = Color("screenBackground")
    static let sheetBackground = Color("sheetBackground")
    static let cardSurface = Color("cardSurface")

    static let textPrimary = Color("textPrimary")
    static let textMuted = Color("textMuted")
    static let textPlaceholder = Color("textPlaceholder")

    static let hairline = Color("hairline")
    static let stepperFieldBg = Color("stepperFieldBg")

    static let goldStart = Color("goldStart")
    static let goldEnd = Color("goldEnd")
    static let goldAccentText = Color("goldAccentText")

    static let chipTint = Color("chipTint")
    static let drawChipBg = Color("drawChipBg")
    static let drawChipText = Color("drawChipText")

    static let successToggle = Color("successToggle")

    /// Destructive actions only (delete a child/tournament/match, and their confirmations).
    static let destructive = Color("destructive")
}

extension LinearGradient {
    static let goldGradient = LinearGradient(
        colors: [.goldStart, .goldEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
