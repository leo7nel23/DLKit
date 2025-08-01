//
//  DLVVM+NavigationState.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/7/18.
//

import Foundation
import SwiftUI

public typealias NavigationFlow = DLVVM.NavigationFlow

public extension DLVVM {
    final class NavigationFlow: NavigatableState, @unchecked Sendable, Identifiable {
        public typealias R = NavigationFeature
        public typealias NavigatorEvent = Void

        public let id: String = UUID().uuidString

        let viewBuilder: CoordinatorViewBuilder

        private(set) var rootInfo: NavigatorInfo!
        var manager: Navigator!

        let stateTypeList: [any BusinessState.Type]

        public let eventHandler: ((Any) -> Any?)?

        public init(
            stateTypeList: [any BusinessState.Type],
            viewBuilder: @escaping CoordinatorViewBuilder,
            eventHandler: ((Any) -> Any?)? = nil
        ) {
            var list = stateTypeList
            list.append(NavigationFlow.self)
            self.stateTypeList = list
            self.viewBuilder = viewBuilder
            self.eventHandler = eventHandler
        }

        func setUp(rootViewModel: any DLViewModelProtocol) {
            rootInfo = NavigatorInfo(viewModel: rootViewModel)
            if manager == nil {
                manager = Navigator(
                    rootInfo: rootInfo,
                    id: id,
                    viewBuilder: viewBuilder
                )
            }
        }

        @MainActor
        func buildView(for navigatorInfo: NavigatorInfo) -> AnyView {
            let view: any View = {
                if let navigator = navigatorInfo.viewModel as? DLViewModel<NavigationFlow> {
                    DLNavigationView(viewModel: navigator)
                } else {
                    manager.buildView(for: navigatorInfo)
                }
            }()
            return AnyView(view)
        }
    }
}
