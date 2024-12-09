//
//  DLActionReducibleViewModel.swift
//
//
//  Created by 賴柏宏 on 2024/7/30.
//

import Foundation

public typealias DLReducibleViewModel = DevinLaiReducibleViewModel
public protocol DevinLaiReducibleViewModel: DLPropertiesViewModel {
  associatedtype Reducer: DLReducer where Reducer.ViewModel == Self
}

public extension DevinLaiReducibleViewModel {
  
  func reduce(_ action: Reducer.Action) {
    Reducer.reduce(action, with: properties)
  }
  
  func makeSubViewModel<T: DLViewModel & DLEventPublisher>(
    _ maker: () -> T,
    convertAction: @escaping (T.Event) -> Reducer.Action?
  ) -> T {
    let viewModel: T = maker()
    
    viewModel.eventPublisher
      .sink { [weak self] event in
        guard let self,
              let action = convertAction(event)
        else { return }
        self.reduce(action)
      }
      .store(in: &subscriptions)
    
    return viewModel
  }
}
