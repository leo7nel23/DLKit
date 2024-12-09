//
//  DLViewModel.swift
//
//
//  Created by 賴柏宏 on 2024/7/17.
//

import Foundation

public typealias DLViewModel = DevinLaiViewModel

public protocol DevinLaiViewModel: AnyObject {

}

extension DLViewModel {
  func makeSubViewModel<T: DLViewModel>(
    _ maker: () -> T
  ) -> T {
    maker()
  }
}
