//
//  File.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/9.
//

import Foundation

public protocol DLCoordinatable: AnyObject {
  associatedtype T: DestinationCase
  var coordinator: DefaultCoordinatorViewModel<T>? { get set }
}

public extension DLCoordinatable {
  func set<V: DestinationCase>(coordinator: DefaultCoordinatorViewModel<V>) {
    if let coordinator = coordinator as? DefaultCoordinatorViewModel<T> {
      self.coordinator = coordinator
    }
  }
}
