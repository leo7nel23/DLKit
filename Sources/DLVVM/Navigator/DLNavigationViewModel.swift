//
//
//  NavigationViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/9.
//
//

import Combine

public typealias DLNavigationViewModel = DLNavigationView.NavigationViewModel

// MARK: - DLVVM.NavigationViewModel
public extension DLNavigationView {
    enum NavigationReducer: BusinessReducer {
        public class State: BusinessState {
            public typealias ViewModel = NavigationViewModel

            let rootViewModel: any DLViewModel
            let viewBuilder: CoordinatorViewBuilder

            init(
                rootViewModel: any DLViewModel,
                viewBuilder: @escaping CoordinatorViewBuilder
            ) {
                self.rootViewModel = rootViewModel
                self.viewBuilder = viewBuilder
            }
        }

        public typealias Action = Void
        public static func reduce(into state: inout State, action: Void) {}
    }
    @MainActor
    final class NavigationViewModel: DLViewModel {
        public var state: NavigationReducer.State
        
        public typealias Reducer = NavigationReducer

        let id: String = UUID().uuidString

        public var subscriptions = Set<AnyCancellable>()

        var manager: NavigationManager

        private var root: NavigatorInfo

        var result: Any?

        private let viewBuilder: CoordinatorViewBuilder

        public init(initialState: NavigationReducer.State) {
            self.state = initialState
            let root = NavigatorInfo(viewModel: initialState.rootViewModel)
            self.root = root
            self.viewBuilder = initialState.viewBuilder
            manager = NavigationManager(
                rootViewModel: root,
                id: id,
                viewBuilder: viewBuilder
            )
        }

        public convenience init(
            rootViewModel: any DLViewModel,
            viewBuilder: @escaping CoordinatorViewBuilder
        ) {
            self.init(
                initialState: NavigationReducer.State(
                    rootViewModel: rootViewModel,
                    viewBuilder: viewBuilder
                )
            )
        }

        public func push(_ viewModel: any DLViewModel) {
            if let coordinatorViewModel = viewModel as? NavigationViewModel {
                manager.createNewPath(
                    for: coordinatorViewModel.id,
                    with: coordinatorViewModel.root,
                    viewBuilder: coordinatorViewModel.viewBuilder
                )
                coordinatorViewModel.manager = manager
            } else {
                manager.push(NavigatorInfo(viewModel: viewModel))
            }
        }

        public func push(_ coordinator: any Coordinator) {
            push(coordinator.navigationViewModel)
        }

        public func presentSheet(_ viewModel: any DLViewModel) {
            manager.sheet = NavigatorInfo(viewModel: viewModel)
        }

        public func presentFullScreenCover(_ viewModel: any DLViewModel) {
            manager.fullScreenCover = NavigatorInfo(viewModel: viewModel)
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

        public func dismiss() {
            manager.dismiss()
        }

        public func update(result: Any?) {
            self.result = result
        }

        public func alert(_ viewModel: AlertViewModel) {
            manager.alert(viewModel)
        }

        func buildView(for coordinatorInfo: NavigatorInfo) -> AnyView {
            let view: any View = {
                if let coordinatorViewModel = coordinatorInfo.viewModel as? NavigationViewModel {
                    return DLNavigationView(viewModel: coordinatorViewModel)
                } else {
                    return manager.buildView(for: coordinatorInfo)
                }
            }()
            return AnyView(view)
        }
    }
}
