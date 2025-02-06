//
//  DLView.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import SwiftUI

public protocol DLView: View {
  associatedtype ViewModel: DLViewModel

  var viewModel: ViewModel { get }

  init(viewModel: ViewModel)
}

public extension DLView where ViewModel: DLViewAction {
    func send(_ viewAction: ViewModel.ViewAction) {
        viewModel.reduce(viewAction)
    }
}
