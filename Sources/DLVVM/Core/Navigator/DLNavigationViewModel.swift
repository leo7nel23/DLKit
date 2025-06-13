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
                
            case .alert:
                break
            }
            
            return .none
        }
    }
}
