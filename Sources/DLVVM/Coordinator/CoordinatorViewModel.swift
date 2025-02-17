//
//
//  CoordinatorViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/9.
//
//

import Combine

public typealias CoordinatorViewModel = CoordinatorView.CoordinatorViewModel

// MARK: - DLVVM.CoordinatorViewModel

public extension CoordinatorView {
    @MainActor
    class CoordinatorViewModel: DLViewModel {
        var manager: NavigationManager
        let id: String = UUID().uuidString
        var root: CoordinatorableViewModel
        var result: Any?

        let viewBuilder: CoordinatorViewBuilder
        let callback: CoordinatorCallback<Any?>?

        public init(
            rootViewModel: DLViewModel,
            viewBuilder: @escaping CoordinatorViewBuilder,
            callback: CoordinatorCallback<Any?>? = nil
        ) {
            let root = CoordinatorableViewModel(viewModel: rootViewModel)
            self.root = root
            self.viewBuilder = viewBuilder
            self.callback = callback
            manager = NavigationManager(
                rootViewModel: root,
                id: id,
                viewBuilder: viewBuilder
            )
        }

        public func push(_ viewModel: DLViewModel) {
            if let coordinatorViewModel = viewModel as? CoordinatorViewModel {
                setCoordinator(viewModel: coordinatorViewModel.root.viewModel)
                manager.createNewPath(
                    for: coordinatorViewModel.id,
                    with: coordinatorViewModel.root,
                    viewBuilder: coordinatorViewModel.viewBuilder
                )
                coordinatorViewModel.manager = manager
            } else {
                manager.push(CoordinatorableViewModel(viewModel: viewModel))
            }
        }

        public func presentSheet(_ viewModel: DLViewModel) {
            manager.sheet = CoordinatorableViewModel(viewModel: viewModel)
        }

        public func presentFullScreenCover(_ viewModel: DLViewModel) {
            manager.fullScreenCover = CoordinatorableViewModel(viewModel: viewModel)
        }

        public func pop() {
            manager.pop()
        }

        public func popToRoot() {
            manager.popToRoot()
        }

        public func dismissSheet() {
            manager.sheet = nil
        }

        public func dismissFullScreenOver() {
            manager.fullScreenCover = nil
        }

        public func dismiss(runCallback: Bool = true) {
            if runCallback {
                callback?.run(result)
            }
            manager.dismiss()
        }

        public func update(result: Any?) {
            self.result = result
        }

        private func setCoordinator(viewModel: DLViewModel) {
            if let viewModel = viewModel as? NavigationCapable {
                viewModel.coordinator = self
            }
        }

        func buildView(for hashableViewModel: CoordinatorableViewModel) -> AnyView {
            let view: any View = {
                if let coordinatorViewModel = hashableViewModel.viewModel as? CoordinatorViewModel {
                    setCoordinator(viewModel: coordinatorViewModel.manager.root.viewModel)
                    return CoordinatorView(viewModel: coordinatorViewModel)
                } else {
                    setCoordinator(viewModel: hashableViewModel.viewModel)
                    return manager.buildView(for: hashableViewModel)
                }
            }()
            return AnyView(view)
        }
    }
}
