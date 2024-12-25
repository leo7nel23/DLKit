//
//  File.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/9.
//

import Foundation

public protocol DLCoordinatable: DLViewModel {
  associatedtype Coordinator: DLCoordinatorViewModel
  var coordinator: Coordinator? { get set }
}

public extension DLCoordinatable {
  func set(coordinator: any DLCoordinatorViewModel) {
    if let coordinator = coordinator as? Coordinator {
      self.coordinator = coordinator
    }
  }
}
