//
//  DLVVM+NavigationState.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/7/18.
//

import Foundation
import SwiftUI

public typealias NavigationState = DLVVM.NavigationState

public extension DLVVM {
    final class NavigationState: NavigatableState, @unchecked Sendable, Identifiable {
        public typealias R = NavigationReducer
        public typealias NavigatorEvent = Void

        public let id: String = UUID().uuidString

        let viewBuilder: CoordinatorViewBuilder

        private(set) var rootInfo: NavigatorInfo!
        var manager: NavigationManager!

        let stateTypeList: [any NavigatableState.Type]

        public let eventHandler: ((Any) -> Any?)?

        public init(
            stateTypeList: [any NavigatableState.Type],
            viewBuilder: @escaping CoordinatorViewBuilder,
            eventHandler: ((Any) -> Any?)? = nil
        ) {
            var list = stateTypeList
            list.append(NavigationState.self)
            self.stateTypeList = list
            self.viewBuilder = viewBuilder
            self.eventHandler = eventHandler
        }

        func setUp(rootViewModel: any DLViewModelProtocol) {
            rootInfo = NavigatorInfo(viewModel: rootViewModel)
            if manager == nil {
                manager = NavigationManager(
                    rootInfo: rootInfo,
                    id: id,
                    viewBuilder: viewBuilder
                )
            }
        }

        @MainActor
        func buildView(for navigatorInfo: NavigatorInfo) -> AnyView {
            let view: any View = {
                if let navigator = navigatorInfo.viewModel as? Navigator {
                    DLNavigationView(viewModel: navigator)
                } else {
                    manager.buildView(for: navigatorInfo)
                }
            }()
            return AnyView(view)
        }
    }
}