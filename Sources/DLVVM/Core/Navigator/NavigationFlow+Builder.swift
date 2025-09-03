//
//  NavigationFlow+Builder.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/9/3.
//

import SwiftUI

extension DLVVM {
    protocol AnyDLView {
        static var reducerStateType: any BusinessState.Type { get }
    }

    protocol AnyDLViewFactory {
        static func makeIfMatch(viewModel: any DLViewModelProtocol) -> (any View)?
    }
}

extension DLView {
    static var reducerStateType: any BusinessState.Type {
        ReducerState.self
    }

    static func makeIfMatch(viewModel: any DLViewModelProtocol) -> (any View)? {
        // 檢查型別是否吻合
        guard let vm = viewModel as? ViewModel else { return nil }
        return Self.init(viewModel: vm)
    }
}

public extension NavigationFlow {
    @MainActor
    convenience init(
        viewTypes: [any DLView.Type],
        eventHandler: ((Any) -> Any?)? = nil
    ) {
        let stateTypeList = viewTypes.map { $0.reducerStateType }
        self.init(
            stateTypeList: stateTypeList,
            viewBuilder: { viewModel in
                for viewType in viewTypes {
                    if let view = viewType.makeIfMatch(viewModel: viewModel) {
                        return view
                    }
                }
                return nil
            },
            eventHandler: eventHandler
        )
    }
}
