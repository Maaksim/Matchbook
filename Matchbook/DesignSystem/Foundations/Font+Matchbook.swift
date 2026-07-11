import SwiftUI

extension Font {
    /// Unbounded 700 — wordmark, screen titles, stat numbers, card titles.
    static func display(size: CGFloat, relativeTo textStyle: TextStyle = .largeTitle) -> Font {
        .custom("Unbounded-Bold", size: size, relativeTo: textStyle)
    }

    /// Onest 400/500/600 — body text, labels, buttons, tab bar.
    static func ui(size: CGFloat, weight: Weight = .regular, relativeTo textStyle: TextStyle = .body) -> Font {
        .custom(uiFontName(for: weight), size: size, relativeTo: textStyle)
    }

    private static func uiFontName(for weight: Weight) -> String {
        switch weight {
        case .medium:
            "Onest-Medium"
        case .semibold, .bold, .heavy, .black:
            "Onest-SemiBold"
        default:
            "Onest-Regular"
        }
    }
}
