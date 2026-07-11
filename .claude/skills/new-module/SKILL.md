---
name: new-module
description: Scaffold a new feature module following Matchbook's MVVM+C pattern (Coordinator + View + ViewModel). Use when creating new screens or features.
argument-hint: "[ModuleName]"
---

Create a new feature module named `$ARGUMENTS` following the MVVM+C architecture defined in CLAUDE.md and `Matchbook-Technical-Documentation.md` §2.1.

## Steps

1. Create the module's View, ViewModel, and (if it owns a navigation flow) Coordinator files: `FeatureView.swift`, `FeatureViewModel.swift`, `FeatureCoordinator.swift`.
2. If the module reads/writes data, add or extend a Repository protocol (§3.9) — never call `modelContext` directly from a View or ViewModel.
3. Follow the layout conventions from the `swiftui-view` skill and the property-wrapper rules from `state-management` when building the View.
4. Wire the new Coordinator into its parent flow (the owning Coordinator or `RootCoordinator`), matching the navigation map in `Matchbook-Technical-Documentation.md` §4.8.
5. Add a unit test pass for the ViewModel (and Repository, if new) per §2.3 — test against an in-memory `ModelContainer` (`ModelConfiguration(isStoredInMemoryOnly: true)`), never real CloudKit.

## Templates

### SwiftUI View

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

`viewModel` is a plain `let`, not `@State` — the Coordinator creates and owns it (see the "Matchbook: ViewModel Pattern" section of the `/state-management` skill for why).

### ViewModel

```swift
import Observation

@Observable
@MainActor
final class FeatureViewModel {
    private(set) var items: [SomeModel] = []
    private(set) var isLoading = false

    private let repository: FeatureRepository

    // Navigation intents — set by the Coordinator, never decided by the View.
    var onSelect: ((SomeModel) -> Void)?

    init(repository: FeatureRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = await repository.fetchAll()
    }

    func select(_ item: SomeModel) {
        onSelect?(item)
    }
}
```

### Coordinator

```swift
import UIKit

@MainActor
final class FeatureCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let repository: FeatureRepository

    init(navigationController: UINavigationController, repository: FeatureRepository) {
        self.navigationController = navigationController
        self.repository = repository
    }

    func start() {
        let viewModel = FeatureViewModel(repository: repository)
        viewModel.onSelect = { [weak self] item in
            self?.showDetail(for: item)
        }
        let view = FeatureView(viewModel: viewModel)
        navigationController.pushViewController(UIHostingController(rootView: view), animated: true)
    }

    private func showDetail(for item: SomeModel) {
        // push or present the next screen's coordinator/view
    }
}
```

This assumes the `Coordinator` protocol from §2.1 already exists (it's scaffolded once, in WP1, not per-module):

```swift
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}
```

### Repository protocol (only if the module needs persistence)

```swift
protocol FeatureRepository {
    func fetchAll() async -> [SomeModel]
    func create(_ item: SomeModel) throws
    func update(_ item: SomeModel) throws
    func delete(_ item: SomeModel) throws
}
```

Provide a `SwiftDataFeatureRepository` implementation, plus a lightweight in-memory implementation for `#Preview`s and unit tests.

## Rules

- No `NavigationStack`, `NavigationLink`, or `.sheet(isPresented:)` — navigation is a Coordinator decision, forwarded from the ViewModel via a closure property (`onSelect`, `onCreate`, etc.), never decided inside the View.
- No `ObservableObject`, `@StateObject`, `@ObservedObject`, `@Published`, or `Combine` — use `@Observable` (the Observation framework) and `async`/`await` throughout.
- ViewModels are `@MainActor`, `@Observable` classes, one per screen. Coordinators are `@MainActor` classes conforming to `Coordinator`.
- Modal forms (create/edit sheets) are presented by a Coordinator wrapping a `UIHostingController` — standard modal presentation or `UISheetPresentationController` for native sheet chrome — not SwiftUI's `.sheet`.
