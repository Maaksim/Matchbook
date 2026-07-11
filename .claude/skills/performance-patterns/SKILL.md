---
name: performance-patterns
description: Enforce SwiftUI performance best practices — avoid redundant updates, optimize hot paths, lazy loading, and anti-patterns. Applied automatically when writing or reviewing SwiftUI code.
argument-hint: "[review <file-path>]"
---

Enforce SwiftUI performance rules when writing or reviewing code: `$ARGUMENTS`

## Mode: review

When the argument starts with `review`, read the specified file and check it against ALL rules below. Report violations grouped by rule, with line numbers. Suggest concrete fixes for each violation.

## Mode: implicit

When writing any SwiftUI code (including via `/new-module` or `/swiftui-view`), follow ALL rules below automatically.

---

## Rules

### 1. Avoid Redundant State Updates

SwiftUI doesn't compare values before triggering updates. Always guard assignments.

```swift
// BAD — triggers update even if value unchanged
.onReceive(publisher) { value in
    self.currentValue = value
}

// GOOD — only update when different
.onReceive(publisher) { value in
    if self.currentValue != value {
        self.currentValue = value
    }
}
```

### 2. Optimize Hot Paths

Hot paths are frequently executed code (scroll handlers, animations, gestures). Gate state updates by threshold or boolean flip.

```swift
// BAD — updates state on every scroll pixel
.onPreferenceChange(ScrollOffsetKey.self) { offset in
    shouldShowTitle = offset.y <= -32
}

// GOOD — only update when threshold crossed
.onPreferenceChange(ScrollOffsetKey.self) { offset in
    let shouldShow = offset.y <= -32
    if shouldShow != shouldShowTitle {
        shouldShowTitle = shouldShow
    }
}
```

This also applies to `GeometryReader` and `onPreferenceChange` size updates:

```swift
// BAD — fires on every pixel change
.onPreferenceChange(ViewSizeKey.self) { size in
    currentSize = size
}

// GOOD — only updates on significant change
.onPreferenceChange(ViewSizeKey.self) { size in
    if abs(size.width - currentSize.width) > 10 {
        currentSize = size
    }
}
```

> **Note**: `containerRelativeFrame` and `visualEffect` are iOS 17+ alternatives to `GeometryReader`. Do NOT use them until the project migrates from iOS 16+.

### 3. Equatable Views for Expensive Bodies

For views with expensive body computations, conform to `Equatable` and apply `.equatable()`.

```swift
struct ExpensiveView: View, Equatable {
    let data: SomeData

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data.id == rhs.data.id
    }

    var body: some View {
        // Expensive computation
    }
}

// Usage
ExpensiveView(data: data)
    .equatable()
```

**Caution**: If you add new state or dependencies, update the `==` function to include them.

### 4. POD Views for Fast Diffing

POD (Plain Old Data) views use `memcmp` for fastest diffing. A view is POD if it only contains simple value types and no property wrappers.

```swift
// POD view — fastest diffing
struct FastView: View {
    let title: String
    let count: Int

    var body: some View {
        Text("\(title): \(count)")
    }
}

// Non-POD — property wrapper makes it slower to diff
struct SlowerView: View {
    let title: String
    @State private var isExpanded = false

    var body: some View {
        Text(title)
    }
}
```

**Advanced**: Wrap expensive non-POD views in POD parents:

```swift
// POD wrapper — fast memcmp comparison
struct ExpensiveView: View {
    let value: Int

    var body: some View {
        ExpensiveViewInternal(value: value)
    }
}

// Internal view with state
private struct ExpensiveViewInternal: View {
    let value: Int
    @State private var item: Item?

    var body: some View {
        // Expensive rendering
    }
}
```

### 5. Lazy Loading for Large Collections

Use lazy containers for large or dynamic collections.

```swift
// BAD — creates all views immediately
ScrollView {
    VStack {
        ForEach(items) { item in
            ExpensiveRow(item: item)
        }
    }
}

// GOOD — creates views on demand
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ExpensiveRow(item: item)
        }
    }
}
```

### 6. Derived State — Compute, Don't Store

Never store values that can be computed from existing state. Extra `@State` means extra invalidation triggers. See also `/state-management` for full property wrapper selection rules.

```swift
// BAD — derived state stored separately
@State private var items: [Item] = []
@State private var itemCount: Int = 0

// GOOD — compute derived values
@State private var items: [Item] = []

var itemCount: Int { items.count }
```

## Anti-Patterns

### A. Creating Objects in Body

```swift
// BAD — creates new formatter every body call
var body: some View {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return Text(formatter.string(from: date))
}

// GOOD — static or stored formatter
private static let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .long
    return f
}()

var body: some View {
    Text(Self.dateFormatter.string(from: date))
}
```

### B. Heavy Computation in Body

Keep `body` simple and pure — no sorting, filtering, or formatting inline.

```swift
// BAD — sorts array every body call
var body: some View {
    List(items.sorted { $0.name < $1.name }) { item in
        Text(item.name)
    }
}

// GOOD — compute in ViewModel
class ItemsViewModel: ObservableObject {
    @Published private(set) var sortedItems: [Item] = []
    private var cancellables: Set<AnyCancellable> = []

    func setItems(_ items: [Item]) {
        sortedItems = items.sorted { $0.name < $1.name }
    }
}
```

This aligns with the `/swiftui-view` rule that business logic lives in the ViewModel, not in the view body.

### C. Common Performance Bottlenecks

Be aware of:
- **View invalidation storms** from broad state changes
- **Unstable identity** in lists causing excessive diffing (always use stable `id`)
- **Heavy work in `body`** (formatting, sorting, image decoding)
- **Layout thrash** from deep stacks or preference chains (see `/swiftui-view` Rule 4)
- **Computed property re-execution** — extract to separate structs for performance-critical sections (see `/view-structure` Rule 2)

When performance issues arise, suggest profiling with **Instruments → SwiftUI template** to identify specific bottlenecks.

## Debugging

Use `Self._printChanges()` to identify what causes unexpected view updates:

```swift
var body: some View {
    let _ = Self._printChanges()
    // ... rest of body
}
```

Remove before committing — this is a debug-only tool.

## Review Checklist

When reviewing, check every item and report pass/fail:

- [ ] State updates guard against redundant assignments (`if new != old`)
- [ ] Hot paths (scroll, animation, gesture) gate state updates by threshold
- [ ] Large lists use `LazyVStack` / `LazyHStack`
- [ ] No object creation in `body` (DateFormatter, NumberFormatter, etc.)
- [ ] No heavy computation in `body` (sorting, filtering, formatting)
- [ ] Body is simple and pure — no side effects or dispatching
- [ ] Derived state is computed, not stored as separate `@State`
- [ ] `Equatable` + `.equatable()` considered for expensive views
- [ ] No `Self._printChanges()` left in non-debug code
- [ ] Passes `/swiftui-view` layout checklist (flat hierarchy, minimal data passing, etc.)
