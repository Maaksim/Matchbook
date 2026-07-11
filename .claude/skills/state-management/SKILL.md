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

## Property Wrapper Selection Guide

| Wrapper | Use When | Notes |
|---------|----------|-------|
| `@State` | Internal view state that triggers updates | Must be `private` |
| `@Binding` | Child view needs to **modify** parent's state | Don't use for read-only |
| `@StateObject` | View **creates and owns** an `ObservableObject` | Must be `private` |
| `@ObservedObject` | View **receives** an `ObservableObject` from outside | Never create inline |
| `let` | Read-only value passed from parent | Simplest option |
| `var` | Read-only value that child observes via `.onChange()` | For reactive reads |

## Rules

### 1. @State Must Be Private

Always mark `@State` properties as `private`. This makes it clear what's created by the view versus what's passed in.

```swift
// GOOD
@State private var isAnimating = false
@State private var selectedTab = 0

// BAD — exposes internal state in generated init
@State var isAnimating = false
```

### 2. @Binding Only When Child Modifies

Use `@Binding` only when the child view needs to **write back** to the parent's state. If the child only reads, use `let`.

```swift
// GOOD — child modifies the value
struct ToggleView: View {
    @Binding var isSelected: Bool

    var body: some View {
        Button("Toggle") {
            isSelected.toggle()
        }
    }
}

// BAD — child only displays, doesn't modify
struct DisplayView: View {
    @Binding var title: String  // Unnecessary @Binding

    var body: some View {
        Text(title)
    }
}

// GOOD — use let for read-only
struct DisplayView: View {
    let title: String

    var body: some View {
        Text(title)
    }
}
```

### 3. @StateObject vs @ObservedObject — Ownership

- **`@StateObject`**: View **creates and owns** the object — survives view re-creation
- **`@ObservedObject`**: View **receives** the object from outside

```swift
// View creates it → @StateObject
struct OwnerView: View {
    @StateObject private var viewModel = MyViewModel()

    var body: some View {
        ChildView(viewModel: viewModel)
    }
}

// View receives it → @ObservedObject
struct ChildView: View {
    @ObservedObject var viewModel: MyViewModel

    var body: some View {
        List(viewModel.items, id: \.self) { Text($0) }
    }
}
```

**Critical mistake** — never create an `ObservableObject` inline with `@ObservedObject`:

```swift
// WRONG — creates new instance on every view update
struct BadView: View {
    @ObservedObject var viewModel = MyViewModel()  // BUG!
}

// CORRECT — owned objects use @StateObject
struct GoodView: View {
    @StateObject private var viewModel = MyViewModel()
}
```

### 4. Don't Pass Values as @State

Never declare passed values as `@State` or `@StateObject`. The value provided at init is only an **initial** value — subsequent parent updates are ignored.

```swift
// WRONG — child ignores updates from parent
struct ChildView: View {
    @State var item: Item  // Accepts initial value only!

    var body: some View {
        Text(item.name)  // Shows initial value forever
    }
}

// CORRECT — child receives updates
struct ChildView: View {
    let item: Item  // Or @Binding if child needs to modify

    var body: some View {
        Text(item.name)  // Updates when parent changes
    }
}
```

**Prevention**: Always mark `@State` and `@StateObject` as `private`. This prevents them from appearing in the generated initializer, making misuse impossible.

### 5. let vs var for Passed Values

Use `let` for read-only display. Use `var` only when the view needs to react to changes via `.onChange()`.

```swift
// let — simple display
struct ProfileHeader: View {
    private let username: String
    private let avatarUrl: URL

    init(username: String, avatarUrl: URL) {
        self.username = username
        self.avatarUrl = avatarUrl
    }

    var body: some View {
        HStack {
            AsyncImage(url: avatarUrl)
            Text(username)
        }
    }
}

// var — reactive to external changes
struct ReactiveView: View {
    var externalValue: Int

    @State private var displayText = ""

    var body: some View {
        Text(displayText)
            .onChange(of: externalValue) { newValue in
                displayText = "Value changed to \(newValue)"
            }
    }
}
```

### 6. State Privacy — Owned vs Passed

All view-owned state should be `private`. Passed-in values are not private.

```swift
struct MyView: View {
    // Passed from parent — not private
    @Binding var isSelected: Bool
    @ObservedObject var viewModel: SomeViewModel
    let title: String

    // Created by view — private
    @State private var isExpanded = false
    @StateObject private var localViewModel = LocalViewModel()
    @Environment(\.colorScheme) private var colorScheme
}
```

### 7. Avoid Nested ObservableObject

SwiftUI can't track changes through nested `ObservableObject` properties. Changes to the inner object won't trigger view updates.

```swift
// BAD — nested ObservableObject breaks change tracking
class Parent: ObservableObject {
    @Published var child: Child  // Nested — inner changes invisible
}

class Child: ObservableObject {
    @Published var value: Int
}

// GOOD — pass nested object directly to child views
struct ParentView: View {
    @StateObject private var parent = Parent()

    var body: some View {
        ChildView(child: parent.child)
    }
}

struct ChildView: View {
    @ObservedObject var child: Child

    var body: some View {
        Text("\(child.value)")
    }
}
```

## Cassandra-Specific: ViewModel Pattern

In the Cassandra project, module ViewModels are always created in the Assembly and passed to the View. The standard pattern is:

```swift
// Assembly creates the ViewModel — View receives via @StateObject
struct FeatureView: View {
    @StateObject private var viewModel: FeatureViewModel

    init(viewModel: FeatureViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
}
```

This uses `@StateObject` (not `@ObservedObject`) because the view **owns** the lifecycle of the ViewModel once it receives it — the Assembly creates it but the view retains it. See `/swiftui-view` Rule 7 for the structural convention.

## Decision Flowchart

```
Is this value owned by this view?
├─ YES: Is it a simple value type?
│       ├─ YES → @State private var
│       └─ NO (class) → @StateObject private var
│
└─ NO (passed from parent):
    ├─ Need to modify it? → @Binding var
    ├─ ObservableObject? → @ObservedObject var
    └─ Read-only value? → let (or var + .onChange)
```

## Review Checklist

When reviewing, check every item and report pass/fail:

- [ ] All `@State` properties are `private`
- [ ] All `@StateObject` properties are `private`
- [ ] `@Binding` only used when child **modifies** the value (not for read-only)
- [ ] No `@ObservedObject var x = SomeClass()` — owned objects use `@StateObject`
- [ ] No passed values declared as `@State` or `@StateObject`
- [ ] `let` used for read-only passed values (not `@Binding`)
- [ ] No nested `ObservableObject` expecting inner change tracking
- [ ] Cassandra ViewModels use `@StateObject` with `_viewModel = StateObject(wrappedValue:)` init pattern
