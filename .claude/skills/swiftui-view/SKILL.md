---
name: swiftui-view
description: Review or scaffold SwiftUI views following Cassandra layout best practices. Use when creating or reviewing SwiftUI views for layout quality.
argument-hint: "[review <file-path> | scaffold <ViewName>]"
---

Apply Cassandra SwiftUI layout best practices when creating or reviewing views: `$ARGUMENTS`

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
struct ProfileCard: View {
    private let user: UserEntity

    init(user: UserEntity) {
        self.user = user
    }

    var body: some View {
        VStack {
            avatar
            name
            Spacer()
        }
        .padding(.all, 16)
    }
}

// MARK: - UI components
extension ProfileCard {
    private var avatar: some View {
        Image(user.avatar)
            .resizable()
            .frame(width: 30, height: 30)
    }

    private var name: some View {
        Text(user.name)
            .font(.ragSans(.regular, size: 16))
            .foregroundStyle(.clmWhite)
    }
}

// BAD — everything inlined in body
struct ProfileCard: View {
    let user: User

    var body: some View {
        VStack {
            Image(user.avatar)
                .resizable()
                .frame(width: 30, height: 30)
            Text(user.name)
                .font(.ragSans(.regular, size: 16))
                .foregroundStyle(.clmWhite)
            Spacer()
        }
        .padding(.all, 16)
    }
}
```

### 2. Minimal Data Passing — Only Pass What the View Needs

Do not pass an entire entity/model when the view only uses a few fields. Pass individual values instead.

```swift
// GOOD — view only needs a name, so only accept a name
struct UserCard: View {
    private let name: String

    init(name: String) {
        self.name = name
    }

    var body: some View {
        VStack {
            logo
            nameText
            Spacer()
        }
        .padding(.all, 16)
    }
}

// BAD — accepts full entity but only uses one property
struct UserCard: View {
    let user: UserEntity
    // body only uses user.name
}
```

### 3. Own Your Static Container

A custom view must own its static container (VStack, HStack, ZStack). The caller should not be required to wrap the view. However, lazy/repeatable containers (LazyVStack, List, ScrollView) belong to the caller.

```swift
// GOOD — view owns its HStack
struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "star")
            Text("Title")
            Spacer()
        }
    }
}

// BAD — caller must wrap in HStack
struct HeaderView: View {
    var body: some View {
        Image(systemName: "star")
        Text("Title")
    }
}

// GOOD — caller owns the lazy container
struct FeedView: View {
    let items: [Item]

    var body: some View {
        LazyVStack {
            ForEach(items) { item in
                ItemRow(item: item)
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

Business logic must live in the ViewModel (ObservableObject), not in the view body. Views reference action methods on the ViewModel rather than containing inline logic.

```swift
// GOOD — action references a method
struct PublishView: View {
    @StateObject private var viewModel = PublishViewModel()

    var body: some View {
        Button("Publish Project", action: viewModel.handlePublish)
    }
}

// BAD — logic lives in a closure in the view body
struct PublishView: View {
    @State private var isLoading = false

    var body: some View {
        Button("Publish Project") {
            isLoading = true
            apiService.publish(project) { result in
                if case .error = result {
                    showError = true
                }
                isLoading = false
            }
        }
    }
}
```

### 6. Private Properties with Explicit Init

View properties should be `private`. Use an explicit `init` to set them. For `@StateObject`, use `_viewModel = StateObject(wrappedValue:)` in init.

```swift
struct FeatureView: View {
    @StateObject private var viewModel: FeatureViewModel

    init(viewModel: FeatureViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
}
```

For full property wrapper selection rules (`@State` vs `@Binding` vs `@StateObject` vs `@ObservedObject` vs `let`), see the `/state-management` skill.

### 7. Cassandra Styling Conventions

- **Fonts**: Use `.ragSans(_ weight:, size:)` — never raw `.system()` or `.custom()` directly
- **Colors**: Use asset colors (`.clmWhite`, `.clmBlack`, `.clmBackgroundBlack`, etc.) — never raw `Color.white` / `Color.black`
- **Sizes**: Use `SizeConstants` for reusable cell/element sizes
- **Screen dimensions**: Use `Screen.width` / `Screen.height` — never `UIScreen.main.bounds`
- **Spacers**: Use `Spacer(minLength: 0)` when flexible spacing is needed
- **Modern APIs**: Follow the `/modern-apis` skill for deprecated API replacements (`foregroundStyle`, `clipShape`, `Button` vs `onTapGesture`, etc.)
- **Performance**: Follow the `/performance-patterns` skill for avoiding redundant updates, lazy loading, and body anti-patterns
- **View Structure**: Follow the `/view-structure` skill for modifiers vs conditionals, container patterns, and ZStack vs overlay/background

## Scaffold Template

When scaffolding, produce a file following this structure:

```swift
//
//  FeatureView.swift
//  ProjectTarget
//
//  Created by 'developer on DD.MM.YYYY.
//  Copyright © YYYY Cellcom. All rights reserved.
//

import SwiftUI

struct FeatureView: View {
    @StateObject private var viewModel: FeatureViewModel

    init(viewModel: FeatureViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            background
            content
        }
        .ignoresSafeArea()
        .onViewDidLoad {
            viewModel.viewLoaded()
        }
    }
}

// MARK: - UI components
extension FeatureView {
    private var background: some View {
        Color.clmBackgroundBlack
    }
    
    private var content: some View {
        VStack(spacing: 0) {
            // compose named subviews here
            Spacer(minLength: 0)
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
- [ ] No business logic in view body — actions reference ViewModel methods
- [ ] Properties are private with explicit init
- [ ] Uses `.ragSans()` fonts, `.clm*` colors, `Screen.*`, `SizeConstants`
- [ ] File header follows Cassandra template
- [ ] Passes `/modern-apis` review checklist (foregroundStyle, clipShape, Button vs onTapGesture, etc.)
- [ ] Passes `/performance-patterns` review checklist (redundant updates, lazy loading, body anti-patterns, etc.)
- [ ] Passes `/state-management` review checklist (wrapper selection, ownership, privacy, etc.)
- [ ] Passes `/view-structure` review checklist (modifiers vs conditionals, container patterns, overlay vs ZStack, etc.)
