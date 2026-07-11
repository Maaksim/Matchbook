import SwiftUI

/// Rounded-rect "−" / "+" control divided by a 1px hairline, for adjusting a bound
/// count (score, goals, assists). Each button carries its own accessibility label
/// (e.g. "Decrease goals") plus the current value, since the two buttons remain
/// separately focusable controls for VoiceOver rather than one combined element.
struct StepperControl: View {
    @Binding var value: Int
    var minValue: Int = 0
    var maxValue: Int = Int.max
    let decreaseAccessibilityLabel: String
    let increaseAccessibilityLabel: String

    var body: some View {
        HStack(spacing: 0) {
            StepButton(
                image: .minus,
                isEnabled: value > minValue,
                label: decreaseAccessibilityLabel,
                value: value
            ) {
                value = max(minValue, value - 1)
            }

            Rectangle()
                .fill(Color.hairline)
                .frame(width: 1)
                .padding(.vertical, 10)

            StepButton(
                image: .plus,
                isEnabled: value < maxValue,
                label: increaseAccessibilityLabel,
                value: value
            ) {
                value = min(maxValue, value + 1)
            }
        }
        .frame(height: 44)
        .background(Color.stepperFieldBg)
        .clipShape(.rect(cornerRadius: 12))
    }
}

private struct StepButton: View {
    let image: ImageResource
    let isEnabled: Bool
    let label: String
    let value: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(image)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.textPrimary : Color.textPlaceholder)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .accessibilityLabel(label)
        .accessibilityValue("\(value)")
    }
}

#Preview("StepperControl") {
    @Previewable @State var goals = 2

    VStack(spacing: 12) {
        Text("\(goals)")
            .font(.display(size: 34))
            .foregroundStyle(Color.textPrimary)

        StepperControl(
            value: $goals,
            minValue: 0,
            maxValue: 20,
            decreaseAccessibilityLabel: "Decrease goals",
            increaseAccessibilityLabel: "Increase goals"
        )
        .frame(width: 120)
    }
    .padding(24)
    .background(Color.screenBackground)
}
