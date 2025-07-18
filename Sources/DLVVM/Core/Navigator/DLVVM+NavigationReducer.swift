//
//  DLVVM+NavigationReducer.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/7/18.
//

import Foundation

public typealias NavigationReducer = DLVVM.NavigationReducer

public extension DLVVM {
    final class NavigationReducer: Reducer {
        public typealias State = NavigationState
        public typealias Event = Any

        public enum Action {
            case push(any DLViewModelProtocol)
            case presentSheet(any DLViewModelProtocol)
            case presentFullScreenCover(any DLViewModelProtocol)
            case pop
            case popToRoot
            case dismissSheet
            case dismissFullScreenOver
            case dismiss
            case alert(title: String, message: String)
            case subEvent(Any)
        }

        public init() {}

        public func reduce(
            into state: NavigationState,
            action: Action
        ) -> DLVVM.Procedure<Action, State> {
            switch action {
            case let .push(viewModel):
                if let newState = viewModel.state as? NavigationState {
                    state.manager.createNewPath(
                        for: newState.id,
                        with: newState.rootInfo,
                        viewBuilder: newState.viewBuilder
                    )
                    newState.manager = state.manager
                } else {
                    let info = NavigatorInfo(viewModel: viewModel)
                    state.manager.push(info)
                }

            case let .presentSheet(businessState):
                let info = NavigatorInfo(viewModel: businessState)
                state.manager.sheet = info

            case let .presentFullScreenCover(businessState):
                let info = NavigatorInfo(viewModel: businessState)
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

            case let .subEvent(event):
                if let result = state.eventHandler?(event) {
                    fireEvent(result, with: state)
                }

            case .alert:
                break
            }

            return .none
        }
    }
}