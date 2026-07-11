---
name: state-management
description: Enforce correct SwiftUI property wrapper selection and state ownership rules. Applied automatically when writing or reviewing SwiftUI code.
argument-hint: "[review <file-path>]"
---

Enforce SwiftUI state management rules when writing or reviewing code: `$ARGUMENTS`

## Mode: review

When the argument starts with `review`, read the specified file and check it against ALL rules below. Report violations grouped by rule, with line numbers. Suggest concrete fixes for each violation.

## Mode: implicit

When writing any SwiftUI code (including via `/new-module` or `/swiftui-view`), follow ALL rules below automatically.

---

Matchbook uses the **Observation framework** (`@Observable`) exclusively — never `ObservableObject`, `@StateObject`, `@ObservedObject`, `@Published`, or Combine (Matchbook-Technical-Documentation.md §2). That changes which wrapper plays the "owns this reference type" role versus older SwiftUI code you may have seen elsewhere.

## Property Wrapper Selection Guide

| Wrapper | Use When | Notes |
|---------|----------|-------|
| `@State` (value type) | View's own internal state that triggers updates | Must be `private` |
| `@State` (`@Observable` reference) | View **creates and owns** an `@Observable` model — survives the view struct being recreated | Must be `private`; this replaces `@StateObject`'s role |
| plain `let`/`var` (`@Observable` reference) | View **receives** an `@Observable` model created elsewhere (typically by a Coordinator) | Not private; no wrapper needed for change tracking — this replaces `@ObservedObject`'s role |
| `@Bindable` | Need a two-way `Binding` into a property of an `@Observable` reference (e.g. a `TextField`) | See Rule 4 |
| `@Binding` | Child needs to **write back** to a parent's plain value-type state | Don't use for read-only |
| `let` | Read-only plain value passed from parent | Simplest option |
| `@Environment` | Read a value supplied up the view tree (e.g. `\.modelContext`, `\.colorScheme`) | |

## Rules

### 1. @State Must Be Private

Always mark `@State` properties `private` — both for plain value state and for an `@Observable` model the view itself creates.

```swift
// GOOD
@State private var isAnimating = false
@State private var viewModel = FeatureViewModel(repository: LiveFeatureRepository())

// BAD — exposes internal state in the generated init
@State var isAnimating = false
```

### 2. @Binding Only When Child Modifies a Plain Value

Use `@Binding` only when the child view needs to **write back** to the parent's plain value-type state. If the child only reads, use `let`.

```swift
// GOOD — child modifies the value
struct MotmToggle: View {
    @Binding var isMotm: Bool

    var body: some View {
        Toggle("Player of the Match", isOn: $isMotm)
    }
}

// BAD — child only displays, doesn't modify
struct ScoreLabel: View {
    @Binding var scoreLine: String   // Unnecessary @Binding

    var body: some View {
        Text(scoreLine)
    }
}

// GOOD — use let for read-only
struct ScoreLabel: View {
    let scoreLine: String

    var body: some View {
        Text(scoreLine)
    }
}
```

### 3. Owning vs Receiving an @Observable Model

- The view **creates** the model → `@State private var viewModel = FeatureViewModel(...)`
- The view **receives** the model from outside (a Coordinator, in Matchbook's MVVM+C) → plain `let viewModel: FeatureViewModel` (or non-private `var` if it must be reassigned)

Unlike `ObservableObject`, `@Observable` does **not** need a property wrapper to participate in view updates — SwiftUI tracks whichever properties `body` actually reads, anywhere in the object graph reachable from a plain `let`/`var`. The wrapper choice here is about **lifecycle ownership** (does this view's own state need to survive it being recreated?), not about whether the view updates.

**Critical mistake** — never give an owned `@Observable` model a default value on a non-`@State` property:

```swift
// WRONG — SwiftUI can recreate FeatureView's struct on every parent update,
// re-running this default initializer and silently discarding all prior state
struct BadView: View {
    let viewModel = FeatureViewModel(repository: LiveFeatureRepository())
}

// CORRECT — an owned model uses @State so it survives the view being recreated
struct GoodOwnedView: View {
    @State private var viewModel = FeatureViewModel(repository: LiveFeatureRepository())
}

// ALSO CORRECT — model created elsewhere (e.g. a Coordinator) and injected, no default value
struct GoodInjectedView: View {
    let viewModel: FeatureViewModel
}
```

### 4. @Bindable for Two-Way Bindings into an Observable Model

When a view needs `$viewModel.someProperty` (e.g. to bind a `TextField` directly to a ViewModel property), declare the property `@Bindable` instead of a plain `let`/`var`:

```swift
struct MatchEditView: View {
    @Bindable var viewModel: MatchEditViewModel

    var body: some View {
        TextField("Opponent", text: $viewModel.opponent)
    }
}
```

`@Bindable` doesn't imply ownership — the model can still have been created by a Coordinator and merely handed to this view. Use it whenever you need the `$`-binding projection; use plain `let`/`var` (Rule 3) when the view only reads properties or calls methods.

### 5. let vs var for Passed Plain Values

Use `let` for read-only display. Use `var` only when the view needs to react to external changes via `.onChange(of:)`.

```swift
// let — simple display
struct PlayerHeader: View {
    let name: String
    let shirtNumber: Int

    var body: some View {
        HStack {
            Text(name)
            Text("#\(shirtNumber)")
        }
    }
}

// var — reactive to external changes
struct GoalCounter: View {
    var goals: Int

    @State private var displayText = ""

    var body: some View {
        Text(displayText)
            .onChange(of: goals) { _, newValue in
                displayText = "\(newValue) goals"
            }
    }
}
```

### 6. State Privacy — Owned vs Received

All view-owned state should be `private`. Received values (bindings, injected models, plain data) are not private.

```swift
struct MatchEditView: View {
    // Received from a Coordinator or parent — not private
    @Bindable var viewModel: MatchEditViewModel
    @Binding var isPresented: Bool
    let tournamentName: String

    // Created by this view — private
    @State private var isExpandedDetails = false
    @State private var localDraft = MatchDraft()
    @Environment(\.modelContext) private var modelContext
}
```

### 7. Nested @Observable Properties Propagate Automatically

Unlike `ObservableObject`/Combine — where a nested `ObservableObject` held by a `@Published` property couldn't propagate its own inner changes — `@Observable` correctly tracks changes through nested observable references. You don't need to manually re-publish or flatten state to make inner changes visible.

```swift
@Observable
@MainActor
final class TournamentDetailViewModel {
    var summary: MatchSummaryViewModel   // nested @Observable — changes propagate correctly
}

@Observable
@MainActor
final class MatchSummaryViewModel {
    var goals: Int = 0
}
```

## Matchbook: ViewModel Pattern

In Matchbook's MVVM+C architecture, a screen's ViewModel is always created by the owning Coordinator and handed to the View through its initializer — the View never creates its own ViewModel (Matchbook-Technical-Documentation.md §2.1; see also the `/new-module` skill).

```swift
// Coordinator creates the ViewModel — the View receives it, doesn't own its lifecycle
@MainActor
final class TournamentCoordinator: Coordinator {
    func start() {
        let viewModel = TournamentListViewModel(player: player, repository: repository)
        let view = TournamentListView(viewModel: viewModel)
        navigationController.pushViewController(UIHostingController(rootView: view), animated: true)
    }
}

struct TournamentListView: View {
    let viewModel: TournamentListViewModel   // received, not owned — plain `let`, no @State
}
```

Use a plain `let` here (Rule 3) because the Coordinator owns the ViewModel's lifecycle. Reach for `@Bindable` (Rule 4) only when the view needs a `Binding` into one of the ViewModel's own properties.

## Decision Flowchart

```
Is this an @Observable reference type (a ViewModel)?
├─ Created by this view? → @State private var viewModel = FeatureViewModel(...)
└─ Created elsewhere (e.g. a Coordinator) and passed in?
    ├─ Need a $-Binding into one of its properties? → @Bindable var viewModel: FeatureViewModel
    └─ Just reading properties / calling methods? → let viewModel: FeatureViewModel

Is this a plain value (not an @Observable reference)?
├─ Owned by this view → @State private var value = ...
├─ Passed from parent, this view writes back → @Binding var value: T
└─ Passed from parent, read-only → let value: T
```

## Review Checklist

When reviewing, check every item and report pass/fail:

- [ ] All `@State` properties (plain value or owned `@Observable` model) are `private`
- [ ] `@Binding` only used when the child **modifies** a plain value (not for read-only)
- [ ] No `ObservableObject`, `@StateObject`, `@ObservedObject`, `@Published`, or `Combine` import anywhere
- [ ] A ViewModel received from a Coordinator is held as a plain `let`/`var` (or `@Bindable` if a `$`-binding is needed) — not `@State`
- [ ] No `@Observable` model given a default value on a non-`@State` property (silently recreated on every redraw)
- [ ] `let` used for read-only passed plain values (not `@Binding`)
- [ ] `@Bindable` used wherever the view needs `$viewModel.property`, instead of a hand-rolled `Binding`
