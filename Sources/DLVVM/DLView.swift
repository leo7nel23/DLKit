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
        associatedtype ViewModel: DLViewModel

        var viewModel: ViewModel { get }

        init(viewModel: ViewModel)
    }
}

public extension DLView where ViewModel: ViewActionHandler {
    func send(_ viewAction: ViewModel.ViewAction) {
        viewModel.handleViewAction(viewAction)
    }
}
