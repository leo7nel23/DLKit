//
//  DLViewModel.swift
//
//
//  Created by 賴柏宏 on 2024/7/17.
//

import Foundation

public typealias DLViewModel = DevinLaiViewModel

// MARK: - DevinLaiViewModel
public protocol DevinLaiViewModel: AnyObject {
  associatedtype ViewObservation

  var observation: ViewObservation { get }
}

public extension DLViewModel {
  func makeSubViewModel<T: DLViewModel>(
    _ maker: () -> T
  ) -> T {
    maker()
  }
}
