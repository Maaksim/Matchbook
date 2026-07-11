---
name: new-module
description: Scaffold a new feature module following the Cassandra Assembly/Router/View+ViewModel pattern. Use when creating new screens or features.
argument-hint: "[ModuleName] [target: tvos|ios|both]"
---

Create a new feature module named `$ARGUMENTS` following the Cassandra project architecture defined in CLAUDE.md.

## Steps

1. Create folder structure: `ModuleName/Assembly/`, `ModuleName/Router/`, `ModuleName/View+ViewModel/`
2. Create all files from the templates below, replacing `Feature` with the actual module name
3. Follow the SwiftUI layout conventions from the `swiftui-view` skill when building the View

## Templates

### SwiftUI View

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

### ViewModel

```swift
//
//  FeatureViewModel.swift
//  ProjectTarget
//
//  Created by 'developer' on DD.MM.YYYY.
//  Copyright © YYYY Cellcom. All rights reserved.
//

import Combine

class FeatureViewModel: ObservableObject {
    private let router: FeatureRouterProtocol
    private let useCase: FeatureUseCaseProtocol
    private var cancellables: Set<AnyCancellable> = []

    init(router: FeatureRouterProtocol, useCase: FeatureUseCaseProtocol) {
        self.router = router
        self.useCase = useCase
        bindUseCase()
    }

    func viewLoaded() {
        useCase.loadData()
    }

    private func bindUseCase() {
        useCase.dataSubject
            .sink { [weak self] data in
                guard let self else { return }
                // handle data
            }
            .store(in: &cancellables)
    }
}
```

### Assembly

```swift
//
//  FeatureAssembly.swift
//  ProjectTarget
//
//  Created by 'developer on DD.MM.YYYY.
//  Copyright © YYYY Cellcom. All rights reserved.
//

import UIKit

struct FeatureAssembly {
    func make() -> UIViewController {
        let useCase = FeatureUseCase()
        let router = FeatureRouter()
        let viewModel = FeatureViewModel(router: router, useCase: useCase)
        let view = FeatureView(viewModel: viewModel)
        let viewController = view.hosted()
        router.setup(viewController: viewController)
        return viewController
    }
}
```

### Router

```swift
//
//  FeatureRouter.swift
//  ProjectTarget
//
//  Created by 'developer on DD.MM.YYYY.
//  Copyright © YYYY Cellcom. All rights reserved.
//

import UIKit

protocol FeatureRouterProtocol {
    func pushDetail(item: SomeEntity)
    func presentError(for type: ErrorType)
}

class FeatureRouter: FeatureRouterProtocol {
    private weak var viewController: UIViewController?
    private let errorRouter = ErrorRouter()

    func setup(viewController: UIViewController) {
        self.viewController = viewController
    }

    func pushDetail(item: SomeEntity) {
        let detailVC = DetailAssembly().make(item: item)
        viewController?.navigationController?.pushViewController(detailVC, animated: true)
    }

    func presentError(for type: ErrorType) {
        guard let topVC = viewController else { return }
        errorRouter.presentError(on: topVC, errorType: type)
    }
}
```

### ViewModifier

```swift
//
//  FeatureModifier.swift
//  ProjectTarget
//
//  Created by 'developer on DD.MM.YYYY.
//  Copyright © YYYY Cellcom. All rights reserved.
//

import SwiftUI

struct FeatureModifier: ViewModifier {
    let someParam: CGFloat

    func body(content: Content) -> some View {
        content
            // apply modifications
    }
}

extension View {
    func featureStyle(someParam: CGFloat) -> some View {
        self.modifier(FeatureModifier(someParam: someParam))
    }
}
```

### UseCase (cellcom-apple-core)

```swift
//
//  FeatureUseCase.swift
//  CellcomCore
//
//  Created by 'developer on DD.MM.YYYY.
//  Copyright © YYYY Cellcom. All rights reserved.
//

import Foundation
import Combine

public protocol FeatureUseCaseProtocol {
    var dataSubject: PassthroughSubject<SomeEntity, Never> { get }
    var errorSubject: PassthroughSubject<NetworkErrorInfoEntity, Never> { get }

    func loadData()
}

public class FeatureUseCase: FeatureUseCaseProtocol {
    @CoreService(\.inMemoryRepository) private var inMemoryRepository

    public var dataSubject = PassthroughSubject<SomeEntity, Never>()
    public var errorSubject = PassthroughSubject<NetworkErrorInfoEntity, Never>()

    private let apiService: FeatureApiServiceProtocol
    private var cancellables: Set<AnyCancellable> = []

    public init(apiService: FeatureApiServiceProtocol) {
        self.apiService = apiService
    }

    public func loadData() {
        // call apiService, send results via dataSubject
    }
}
```
