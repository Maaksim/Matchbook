---
name: modern-apis
description: Enforce modern SwiftUI API usage — deprecated API replacements and best practices. Applied automatically when writing or reviewing SwiftUI code.
argument-hint: "[review <file-path>]"
---

Enforce modern SwiftUI API rules when writing or reviewing code: `$ARGUMENTS`

## Mode: review

When the argument starts with `review`, read the specified file and check it against ALL rules below. Report violations grouped by rule, with line numbers. Suggest concrete fixes for each violation.

## Mode: implicit

When writing any SwiftUI code (including via `/new-module` or `/swiftui-view`), follow ALL rules below automatically.

---

## Rules

### 1. foregroundStyle() over foregroundColor()

**Always use `foregroundStyle()` instead of `foregroundColor()`.**

```swift
// GOOD
Text("Hello")
    .foregroundStyle(.clmBlue)

Image(systemName: "star")
    .foregroundStyle(.clmBlue)

// BAD
Text("Hello")
    .foregroundColor(.clmBlue)
```

`foregroundStyle()` supports hierarchical styles, gradients, and materials.

### 2. clipShape() over cornerRadius()

**Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.**

```swift
// GOOD
Image(.photo)
    .clipShape(.rect(cornerRadius: 12))

VStack { }
    .clipShape(.rect(cornerRadius: 16))

// BAD — deprecated
Image(.photo)
    .cornerRadius(12)
```

**Note**: The project also has a custom `.corner(radius:)` ViewModifier that uses `clipShape(RoundedRectangle(...))` internally — that is acceptable.

### 3. Button over onTapGesture()

**Never use `onTapGesture()` unless you specifically need tap location or tap count. Always use `Button` otherwise.**

```swift
// GOOD — standard tap action
Button("Tap me") {
    performAction()
}

// GOOD — need tap location
Text("Tap anywhere")
    .onTapGesture { location in
        handleTap(at: location)
    }

// GOOD — need tap count
Image(.photo)
    .onTapGesture(count: 2) {
        handleDoubleTap()
    }

// BAD — use Button instead
Text("Tap me")
    .onTapGesture {
        performAction()
    }
```

`Button` provides proper accessibility, visual feedback, and semantic meaning.

### 4. Avoid AnyView — Use @ViewBuilder

**Avoid `AnyView` unless absolutely required. Use `@ViewBuilder` for conditional content.**

```swift
// GOOD
@ViewBuilder
private var content: some View {
    if condition {
        Text("Option A")
    } else {
        Image(systemName: "photo")
    }
}

// BAD — type erasure has performance cost
func content() -> AnyView {
    if condition {
        return AnyView(Text("Option A"))
    } else {
        return AnyView(Image(systemName: "photo"))
    }
}
```

### 5. Avoid UIKit Colors in SwiftUI

**Use SwiftUI asset colors (`.clm*` prefix). Never bridge UIKit colors.**

```swift
// GOOD — project asset colors
Text("Hello")
    .foregroundStyle(.clmWhite)
    .background(.clmBackgroundBlack)

// BAD — UIKit bridge
Text("Hello")
    .foregroundStyle(Color(UIColor.systemBlue))
    .background(Color(UIColor.systemGray))
```

### 6. Static Member Lookup

**Prefer static member lookup over explicit type names.**

```swift
// GOOD
Circle()
    .fill(.blue)
Button("Action") { }
    .buttonStyle(.borderedProminent)

// VERBOSE
Circle()
    .fill(Color.blue)
Button("Action") { }
    .buttonStyle(BorderedProminentButtonStyle())
```

### 7. onChange(of:) — Two-Parameter Closure (after iOS 17 migration)

The single-parameter `onChange(of:) { newValue in }` is deprecated. After the project migrates to **iOS 17 minimum**, switch to the two-parameter form:

```swift
// TARGET (iOS 17+) — use after migration
.onChange(of: score) { oldValue, newValue in
    handleScoreChange(from: oldValue, to: newValue)
}

// CURRENT (iOS 16) — use until migration
.onChange(of: score) { newValue in
    handleScoreChange(newValue)
}
```

> **Now**: The project targets **iOS 16+**, so use the deprecated single-parameter form. When the minimum deployment target moves to iOS 17, switch all usages to the two-parameter form.

## Review Checklist

When reviewing, check every item and report pass/fail:

- [ ] `foregroundStyle()` used instead of `foregroundColor()`
- [ ] `clipShape(.rect(cornerRadius:))` used instead of `.cornerRadius()`
- [ ] `Button` used instead of `onTapGesture()` for standard taps
- [ ] No `AnyView` — `@ViewBuilder` used for conditional content
- [ ] No `Color(UIColor(...))` — project `.clm*` colors used
- [ ] Static member lookup preferred (`.blue` not `Color.blue`)
- [ ] `onChange(of:)` uses single-parameter form (iOS 16); two-parameter form only after iOS 17 migration
- [ ] No iOS 17+ APIs used (`containerRelativeFrame`, `visualEffect`, etc.)
- [ ] Passes `/performance-patterns` checklist for GeometryReader gating, hot paths, etc.
