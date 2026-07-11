---
name: view-structure
description: Enforce SwiftUI view composition rules — modifiers vs conditionals, subview extraction, container patterns, ZStack vs overlay/background. Applied automatically when writing or reviewing SwiftUI code.
argument-hint: "[review <file-path>]"
---

Enforce SwiftUI view structure rules when writing or reviewing code: `$ARGUMENTS`

## Mode: review

When the argument starts with `review`, read the specified file and check it against ALL rules below. Report violations grouped by rule, with line numbers. Suggest concrete fixes for each violation.

## Mode: implicit

When writing any SwiftUI code (including via `/new-module` or `/swiftui-view`), follow ALL rules below automatically.

---

## Rules

### 1. Prefer Modifiers Over Conditional Views

When toggling **the same view** between two visual states, use a modifier (opacity, offset, etc.) instead of `if/else`. Conditional inclusion destroys and recreates view identity, losing state and breaking animations.

```swift
// GOOD — same view, different visual state
SomeView()
    .opacity(isVisible ? 1 : 0)

// BAD — destroys/recreates view identity
if isVisible {
    SomeView()
}
```

**When conditionals ARE appropriate** — fundamentally different views or optional content:

```swift
// GOOD — truly different views
if isLoggedIn {
    DashboardView()
} else {
    LoginView()
}

// GOOD — optional content
if let user {
    UserProfileView(user: user)
}
```

### 2. Extract to Separate Structs for Performance-Critical Sections

When a section is expensive to compute and its inputs don't change often, extract it into a **separate `struct` view** instead of a `private var` computed property. SwiftUI can skip calling `body` on a separate struct when its inputs haven't changed — but it always re-executes computed properties.

```swift
// BAD — complexSection() re-executes on every parent state change
struct ParentView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Button("Tap: \(count)") { count += 1 }
            complexSection  // Re-executes every tap!
        }
    }
}

extension ParentView {
    private var complexSection: some View {
        ForEach(0..<100) { i in
            HStack {
                Image(systemName: "star")
                Text("Item \(i)")
            }
        }
    }
}

// GOOD — ComplexSection.body skipped when inputs don't change
struct ParentView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Button("Tap: \(count)") { count += 1 }
            ComplexSection()
        }
    }
}

private struct ComplexSection: View {
    var body: some View {
        ForEach(0..<100) { i in
            HStack {
                Image(systemName: "star")
                Text("Item \(i)")
            }
        }
    }
}
```

**Cassandra convention**: The project uses `private var` computed properties in extensions as the default extraction pattern (see `/swiftui-view` Rule 1). Use separate structs **only** when you identify a performance-critical section that re-executes unnecessarily — see also `/performance-patterns` for Equatable views and POD wrappers as complementary techniques. Signs to look for:
- The section is expensive (large `ForEach`, complex layout, image processing)
- The parent view has frequently changing state (timers, scroll position, counters)
- The section's inputs don't depend on that changing state

### 3. Container Views — @ViewBuilder Property over Closure

When creating reusable container views, store content as a `@ViewBuilder` property, not a closure. Closures can't be compared, forcing unnecessary re-renders.

```swift
// GOOD — view can be compared and diffed
struct MyContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack {
            Text("Header")
            content
        }
    }
}

// Usage
MyContainer {
    ExpensiveView()
}

// BAD — closure prevents SwiftUI from skipping updates
struct MyContainer<Content: View>: View {
    let content: () -> Content

    var body: some View {
        VStack {
            Text("Header")
            content()
        }
    }
}
```

### 4. ZStack vs overlay/background

Use **`overlay` / `background`** when decorating a primary view — the modified view remains the layout anchor and the decoration adopts its size.

Use **`ZStack`** when composing multiple peer views that jointly define layout, or when the "decoration" must participate in layout sizing.

```swift
// GOOD — decoration that should not change layout sizing
Button("Continue") { }
    .overlay(alignment: .trailing) {
        Image(.lock)
            .padding(.trailing, 8)
    }

// BAD — ZStack when overlay is enough
ZStack(alignment: .trailing) {
    Button("Continue") { }
    Image(.lock)
        .padding(.trailing, 8)
}

// GOOD — background adopts parent's size
HStack(spacing: 12) {
    Image(.tray)
    Text("Inbox")
}
.background {
    Capsule()
        .strokeBorder(.blue, lineWidth: 2)
}

// BAD — in ZStack, Capsule has no size anchor
ZStack {
    HStack(spacing: 12) {
        Image(.tray)
        Text("Inbox")
    }
    Capsule()
        .strokeBorder(.blue, lineWidth: 2)
}
```

**Size proposal behavior**:
- `overlay` / `background`: child implicitly adopts the parent's proposed size — natural for decoration
- `ZStack`: each child participates independently — better for peer composition

**When ZStack is correct**:
- Composing multiple peers (e.g., background color + content layer in a full-screen view)
- The decoration must explicitly participate in layout sizing
- Reserving space, extending tappable bounds, or preventing overlap with neighbors

## Review Checklist

When reviewing, check every item and report pass/fail:

- [ ] Modifiers used for same-view state changes (opacity, offset) — not `if/else`
- [ ] `if/else` only used for fundamentally different views or optional content
- [ ] Performance-critical sections extracted as separate structs when parent has frequent state changes
- [ ] Container views use `@ViewBuilder let content: Content` — not closures
- [ ] `overlay` / `background` used for decoration — `ZStack` only for peer composition or explicit layout participation
