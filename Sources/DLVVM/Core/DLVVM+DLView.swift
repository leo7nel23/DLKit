//
//  DLView.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import SwiftUI

public typealias DLView = DLVVM.DLView

// MARK: - DLVVM.DLView

public extension DLVVM {
    protocol DLView: View {
        associatedtype ReducerState: BusinessState
        typealias Action = ReducerState.R.Action
        typealias ViewModel = DLViewModel<ReducerState>

        var viewModel: ViewModel { get }

        init(viewModel: ViewModel)
    }
}

public extension DLView {
    func send(_ action: Action) {
        viewModel.send(action)
    }
}
