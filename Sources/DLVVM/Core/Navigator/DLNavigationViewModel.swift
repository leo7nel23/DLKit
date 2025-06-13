//
//
//  NavigationViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/9.
//
//

import Combine

public typealias NavigationState = DLNavigationView.NavigationState
public typealias NavigationReducer = DLNavigationView.NavigationReducer
public typealias Navigator = DLViewModel<NavigationState>

// MARK: - DLVVM.NavigationViewModel

public extension Navigator {
    convenience init(
        rootState: any BusinessState,
        viewBuilder: @escaping CoordinatorViewBuilder
    ) {
        self.init(
            initialState: NavigationState(rootState: rootState, viewBuilder: viewBuilder)) {
                NavigationReducer()
            }
    }
}

public extension DLNavigationView {
    final class NavigationState: BusinessState, Identifiable {
        public typealias R = NavigationReducer

        public let id: String = UUID().uuidString

        let rootInfo: NavigatorInfo
        let viewBuilder: CoordinatorViewBuilder

        var manager: NavigationManager

        public init(
            rootState: any BusinessState,
            viewBuilder: @escaping CoordinatorViewBuilder
        ) {
            let rootInfo = NavigatorInfo(state: rootState)
            self.rootInfo = rootInfo
            self.viewBuilder = viewBuilder
            manager = NavigationManager(
                rootInfo: rootInfo,
                id: id,
                viewBuilder: viewBuilder
            )
        }

        @MainActor
        func buildView(for coordinatorInfo: NavigatorInfo) -> AnyView {
            let view: any View = {
                if let navigationState = coordinatorInfo.state as? NavigationState {
                    return DLNavigationView(
                        viewModel: .init(initialState: navigationState) {
                            NavigationReducer()
                        }
                    )
                } else {
                    return manager.buildView(for: coordinatorInfo)
                }
            }()
            return AnyView(view)
        }
    }

    final class NavigationReducer: Reducer {
        public typealias State = NavigationState

        public enum Action {
            case push(any BusinessState)
            case presentSheet(any BusinessState)
            case presentFullScreenCover(any BusinessState)
            case pop
            case popToRoot
            case dismissSheet
            case dismissFullScreenOver
            case dismiss
            case alert(title: String, message: String)
        }

        public typealias Event = Void

        public func reduce(
            into state: NavigationState,
            action: Action
        ) -> DLVVM.Effect<Action> {
            switch action {
            case let .push(businessState):
                if let newState = businessState as? NavigationState {
                    state.manager.createNewPath(
                        for: newState.id,
                        with: newState.rootInfo,
                        viewBuilder: newState.viewBuilder
                    )
                    newState.manager = state.manager
                } else {
                    let info = NavigatorInfo(state: businessState)
                    state.manager.push(info)
                }

            case let .presentSheet(businessState):
                let info = NavigatorInfo(state: businessState)
                state.manager.sheet = info

            case let .presentFullScreenCover(businessState):
                let info = NavigatorInfo(state: businessState)
                state.manager.fullScreenCover = info

            case .pop:
                state.manager.pop()

            case .popToRoot:
                state.manager.popToRoot()

            case .dismissSheet:
                state.manager.sheet = nil

            case .dismissFullScreenOver:
                state.manager.fullScreenCover = nil

            case .dismiss:
                state.manager.dismiss()

            case let .alert(title, message):
                break
            }

            return .none
        }
    }
//


//    final class NavigationViewModel: DLViewModel {
//        public var state: NavigationReducer.State
//
//        public typealias Reducer = NavigationReducer
//
//        public var subscriptions = Set<AnyCancellable>()
//
//        private var root: NavigatorInfo
//
//        private let viewBuilder: CoordinatorViewBuilder
//
//        public init(initialState: NavigationReducer.State) {
//            self.state = initialState
//            self.root = root
//            self.viewBuilder = initialState.viewBuilder
//            manager = NavigationManager(
//                rootViewModel: root,
//                id: id,
//                viewBuilder: viewBuilder
//            )
//        }
//
//        public convenience init(
//            rootViewModel: any DLViewModel,
//            viewBuilder: @escaping CoordinatorViewBuilder
//        ) {
//            self.init(
//                initialState: NavigationReducer.State(
//                    rootViewModel: rootViewModel,
//                    viewBuilder: viewBuilder
//                )
//            )
//        }

//        public func push(_ viewModel: any DLViewModel) {
//            if let coordinatorViewModel = viewModel as? NavigationViewModel {
//                manager.createNewPath(
//                    for: coordinatorViewModel.id,
//                    with: coordinatorViewModel.root,
//                    viewBuilder: coordinatorViewModel.viewBuilder
//                )
//                coordinatorViewModel.manager = manager
//            } else {
//                manager.push(NavigatorInfo(viewModel: viewModel))
//            }
//        }
//
//        public func push(_ coordinator: any Coordinator) {
//            push(coordinator.navigationViewModel)
//        }
//
//        public func presentSheet(_ viewModel: any DLViewModel) {
//            manager.sheet = NavigatorInfo(viewModel: viewModel)
//        }
//
//        public func presentFullScreenCover(_ viewModel: any DLViewModel) {
//            manager.fullScreenCover = NavigatorInfo(viewModel: viewModel)
//        }
//
//        public func pop() {
//            manager.pop()
//        }
//
//        public func popToRoot() {
//            manager.popToRoot()
//        }
//
//        public func dismissSheet() {
//            manager.sheet = nil
//        }
//
//        public func dismissFullScreenOver() {
//            manager.fullScreenCover = nil
//        }
//
//        public func dismiss() {
//            manager.dismiss()
//        }
//
//        public func update(result: Any?) {
//            self.result = result
//        }
//
//        public func alert(_ viewModel: AlertViewModel) {
//            manager.alert(viewModel)
//        }
//    }
}
