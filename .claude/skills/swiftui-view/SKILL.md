---
name: swiftui-view
description: Review or scaffold SwiftUI views following Matchbook layout best practices. Use when creating or reviewing SwiftUI views for layout quality.
argument-hint: "[review <file-path> | scaffold <ViewName>]"
---

Apply Matchbook SwiftUI layout best practices when creating or reviewing views: `$ARGUMENTS`

## Mode: review

When the argument starts with `review`, read the specified file and check it against ALL rules below. Report violations grouped by rule, with line numbers. Suggest concrete fixes for each violation.

## Mode: scaffold

When the argument starts with `scaffold`, generate a new SwiftUI View file following ALL rules below. Use the provided name as the view struct name.

---

## Rules

### 1. Simple Body — Extract Subviews to Extensions

The `body` property must remain a high-level composition of named subviews. Extract any view with 2+ modifiers or any non-trivial layout into a private computed property inside a `// MARK: - UI components` extension.

```swift
// GOOD
struct TournamentCard: View {
    private let tournament: Tournament

    init(tournament: Tournament) {
        self.tournament = tournament
    }

    var body: some View {
        VStack(alignment: .leading) {
            cover
            title
            Spacer()
        }
        .padding(20)
    }
}

// MARK: - UI components
extension TournamentCard {
    private var cover: some View {
        PhotoPlaceholder(caption: "No Cover Photo")
            .frame(height: 160)
    }

    private var title: some View {
        Text(tournament.name)
            .font(.display(size: 20))
            .foregroundStyle(Color.textPrimary)
    }
}

// BAD — everything inlined in body
struct TournamentCard: View {
    let tournament: Tournament

    var body: some View {
        VStack(alignment: .leading) {
            PhotoPlaceholder(caption: "No Cover Photo")
                .frame(height: 160)
            Text(tournament.name)
                .font(.display(size: 20))
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
        .padding(20)
    }
}
```

### 2. Minimal Data Passing — Only Pass What the View Needs

Do not pass an entire model when the view only uses a few fields. Pass individual values instead.

```swift
// GOOD — view only needs a name, so only accept a name
struct PlayerNameLabel: View {
    private let name: String

    init(name: String) {
        self.name = name
    }

    var body: some View {
        Text(name)
            .font(.ui(size: 15))
    }
}

// BAD — accepts the full model but only uses one property
struct PlayerNameLabel: View {
    let player: Player
    // body only uses player.name
}
```

### 3. Own Your Static Container

A custom view must own its static container (VStack, HStack, ZStack). The caller should not be required to wrap the view. However, lazy/repeatable containers (LazyVStack, List, ScrollView) belong to the caller.

```swift
// GOOD — view owns its HStack
struct StatRow: View {
    var body: some View {
        HStack {
            StatPill(value: "12", label: "Tournaments", accessibilityLabel: "12 tournaments")
            StatPill(value: "34", label: "Goals", accessibilityLabel: "34 goals")
        }
    }
}

// GOOD — caller owns the lazy container
struct MatchListView: View {
    let matches: [Match]

    var body: some View {
        LazyVStack {
            ForEach(matches) { match in
                MatchRow(match: match)
            }
        }
    }
}
```

### 4. Flat View Hierarchy — Avoid Layout Thrash

Minimize deep nesting of VStack/HStack/ZStack. Prefer a flatter structure. If nesting exceeds 4 levels, refactor into extracted subviews.

```swift
// BAD — deep nesting causes excessive layout passes
VStack {
    HStack {
        VStack {
            HStack {
                VStack {
                    Text("Deep")
                }
            }
        }
    }
}

// GOOD — flat structure
VStack {
    Text("Shallow")
    Text("Structure")
}
```

### 5. Separate View Logic from Views

Business logic must live in the `@Observable` ViewModel, not in the view body. Views call methods on the ViewModel rather than containing inline logic; the ViewModel calls Repository protocols (§3.9), never `modelContext` directly.

```swift
// GOOD — action references a ViewModel method
struct MatchEditView: View {
    let viewModel: MatchEditViewModel

    var body: some View {
        Button("Save", action: viewModel.save)
    }
}

// BAD — logic and repository access live inline in the view body
struct MatchEditView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isSaving = false

    var body: some View {
        Button("Save") {
            isSaving = true
            modelContext.insert(Match())
            try? modelContext.save()
            isSaving = false
        }
    }
}
```

### 6. Private Owned State, Plain Received Models

`@State` properties the view creates and owns must be `private`. A ViewModel handed to the view by a Coordinator is typically a plain (non-`@State`) property — no wrapper is needed for `@Observable` change tracking, only for lifecycle ownership. See the `/state-management` skill for the full owned-vs-received rules and when `@Bindable` is needed instead.

```swift
struct FeatureView: View {
    let viewModel: FeatureViewModel     // received from a Coordinator — plain `let`

    @State private var isExpanded = false   // owned by this view — private @State

    var body: some View { ... }
}
```

### 7. Matchbook Styling Conventions

- **Fonts**: use `Font.display(size:)` (Unbounded Bold — wordmark, screen titles, stat numbers) and `Font.ui(size:weight:relativeTo:)` (Onest — body, labels, buttons) from `Font+Matchbook.swift`. Never call `.system()` or `.custom()` directly.
- **Colors**: use the asset-catalog-backed statics on `Color` from `Color+Matchbook.swift` (`.brandGreen`, `.textPrimary`, `.textMuted`, `.cardSurface`, `.screenBackground`, `.hairline`, `.goldAccentText`, etc.) or `LinearGradient.goldGradient`. Never use raw `Color.white`/`Color.black`/inline hex except for one-off effects that aren't reusable tokens (e.g. `CardStyle`'s shadow tint).
- **Cards**: use the `.cardStyle(cornerRadius:)` modifier (`CardStyle.swift`) instead of hand-rolling `background`/`clipShape`/`shadow`.
- **Empty photo/cover slots**: use `PhotoPlaceholder`, not a custom placeholder view.
- **Modern APIs**: follow the `/modern-apis` skill for deprecated API replacements (`foregroundStyle`, `clipShape`, `Button` vs `onTapGesture`, etc.)
- **Performance**: follow the `/performance-patterns` skill for avoiding redundant updates, lazy loading, and body anti-patterns.
- **View Structure**: follow the `/view-structure` skill for modifiers vs conditionals, container patterns, and ZStack vs overlay/background.

## Scaffold Template

When scaffolding, produce a file following this structure:

```swift
import SwiftUI

struct FeatureView: View {
    let viewModel: FeatureViewModel

    var body: some View {
        ZStack {
            background
            content
        }
        .task {
            await viewModel.load()
        }
    }
}

// MARK: - UI components
extension FeatureView {
    private var background: some View {
        Color.screenBackground.ignoresSafeArea()
    }

    private var content: some View {
        VStack(spacing: 0) {
            // compose named subviews here
        }
    }
}
```

## Review Checklist

When reviewing, check every item and report pass/fail:

- [ ] Body is a high-level composition of named subviews (no inline views with 2+ modifiers)
- [ ] View only receives the data it actually uses
- [ ] View owns its static container
- [ ] No deeper than 4 levels of nested layout containers
- [ ] No business logic or repository/`modelContext` access in the view body — actions reference ViewModel methods
- [ ] Owned `@State` is `private`; a Coordinator-supplied ViewModel is held as a plain property, not `@State`
- [ ] Uses `Font.display`/`Font.ui`, `Color.*` design-system tokens, and `.cardStyle()` — no raw system fonts/colors
- [ ] No `ObservableObject`/`@StateObject`/`@ObservedObject`/`Combine` — `@Observable` only
- [ ] Passes `/modern-apis` review checklist (foregroundStyle, clipShape, Button vs onTapGesture, etc.)
- [ ] Passes `/performance-patterns` review checklist (redundant updates, lazy loading, body anti-patterns, etc.)
- [ ] Passes `/state-management` review checklist (wrapper selection, ownership, privacy, etc.)
- [ ] Passes `/view-structure` review checklist (modifiers vs conditionals, container patterns, overlay vs ZStack, etc.)
