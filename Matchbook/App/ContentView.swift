import SwiftUI

/// Design-system showcase: composes the reusable components with dummy data so the
/// whole system can be seen running together, not just in isolated previews.
struct ContentView: View {
    @State private var selectedTab = 0
    @State private var goals = 2

    private let tabs = [
        MatchbookTabItem(title: "Album", systemImage: "photo.on.rectangle", selectedSystemImage: "photo.on.rectangle.fill"),
        MatchbookTabItem(title: "Career", systemImage: "trophy", selectedSystemImage: "trophy.fill"),
        MatchbookTabItem(title: "Profile", systemImage: "person.crop.circle", selectedSystemImage: "person.crop.circle.fill")
    ]

    var body: some View {
        ZStack {
            Color.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    statsRow
                    placementRow
                    photoCard
                    stepperCard
                    Button("Add Tournament") { }
                        .buttonStyle(.primary)
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingActionPill(actionName: "Add Match") { }
                .padding(.trailing, 20)
                .padding(.bottom, 12)
        }
        .safeAreaInset(edge: .bottom) {
            MatchbookTabBar(items: tabs, selection: $selectedTab)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Matchbook")
                .font(.display(size: 32))
                .foregroundStyle(Color.textPrimary)
            Text("Design system preview")
                .font(.ui(size: 15))
                .foregroundStyle(Color.textMuted)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(value: "12", label: "Tournaments", accessibilityLabel: "12 tournaments")
            StatPill(value: "34", label: "Goals", accessibilityLabel: "34 goals")
            StatPill(value: "5", label: "Podiums", highlighted: true, accessibilityLabel: "5 podium finishes")
        }
    }

    private var placementRow: some View {
        HStack(spacing: 12) {
            PlacementBadge(medal: "🥇", label: "Champions")
            PlacementBadge(medal: "🥈", label: "Finalists")
        }
    }

    private var photoCard: some View {
        PhotoPlaceholder(caption: "No Cover Photo")
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .cardStyle()
    }

    private var stepperCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goals")
                .font(.ui(size: 13, weight: .semibold, relativeTo: .footnote))
                .textCase(.uppercase)
                .foregroundStyle(Color.textMuted)

            HStack {
                Text("\(goals)")
                    .font(.display(size: 30))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                StepperControl(
                    value: $goals,
                    minValue: 0,
                    maxValue: 20,
                    decreaseAccessibilityLabel: "Decrease goals",
                    increaseAccessibilityLabel: "Increase goals"
                )
                .frame(width: 110)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

#Preview {
    ContentView()
}
