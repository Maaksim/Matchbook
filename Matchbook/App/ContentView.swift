import SwiftUI

/// Design-system showcase: composes the reusable components with dummy data so the
/// whole system can be seen running together, not just in isolated previews.
struct ContentView: View {
    @State private var selectedTab = 0
    @State private var goals = 2

    private let tabs = [
        MatchbookTabItem(title: "tab_album_key",
                         icon: Image(.iconTabAlbum)),
        MatchbookTabItem(title: "tab_tournaments_key",
                         icon: Image(.iconTabTournament)),
        MatchbookTabItem(title: "tab_profile_key",
                         icon: Image(.iconTabProfile))
    ]

    var body: some View {
        ZStack {
            Color.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ShowcaseHeader()
                    ShowcaseStatsRow()
                    ShowcasePlacementRow()
                    ShowcaseCoverPhotoCard()
                    ShowcaseGoalsCard(goals: $goals)
                    Button("add_tournament_key") { }
                        .buttonStyle(.primary)
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingActionPill(actionName: "add_match_key") { }
                .padding(.trailing, 20)
                .padding(.bottom, 12)
        }
        .safeAreaInset(edge: .bottom) {
            MatchbookTabBar(items: tabs, selection: $selectedTab)
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Showcase sections

private struct ShowcaseHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("app_name_key")
                .font(.display(size: 32))
                .foregroundStyle(Color.textPrimary)
            // Developer-facing showcase subtitle, not product copy — deliberately verbatim
            // so it never lands in the String Catalog.
            Text(verbatim: "Design system preview")
                .font(.ui(size: 15))
                .foregroundStyle(Color.textMuted)
        }
    }
}

private struct ShowcaseStatsRow: View {
    // The accessibility labels are the four String Catalog plural keys in live use —
    // VoiceOver reads "12 турнірів" / "12 tournaments", correctly inflected per locale.
    var body: some View {
        HStack(spacing: 12) {
            StatPill(value: 12.formatted(), label: "stat_tournaments_key", accessibilityLabel: Counts.tournaments(12))
            StatPill(value: 34.formatted(), label: "stat_goals_key", accessibilityLabel: Counts.goals(34))
            StatPill(value: 5.formatted(), label: "stat_podiums_key", highlighted: true, accessibilityLabel: "showcase_podiums_accessibility_key")
        }
    }
}

private struct ShowcasePlacementRow: View {
    var body: some View {
        HStack(spacing: 12) {
            PlacementBadge(medal: "🥇", label: "Чемпіони")
            PlacementBadge(medal: "🥈", label: "Фіналісти")
        }
    }
}

private struct ShowcaseCoverPhotoCard: View {
    var body: some View {
        PhotoPlaceholder(caption: "no_cover_photo_key")
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .cardStyle()
    }
}

private struct ShowcaseGoalsCard: View {
    @Binding var goals: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stat_goals_key")
                .font(.ui(size: 13, weight: .semibold, relativeTo: .footnote))
                .textCase(.uppercase)
                .foregroundStyle(Color.textMuted)

            HStack {
                Text(goals.formatted())
                    .font(.display(size: 30))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                StepperControl(
                    value: $goals,
                    minValue: 0,
                    maxValue: 20,
                    decreaseAccessibilityLabel: "decrease_goals_accessibility_key",
                    increaseAccessibilityLabel: "increase_goals_accessibility_key"
                )
                .frame(width: 110)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}
