//
//  DLReducer.swift
//
//
//  Created by 賴柏宏 on 2024/7/30.
//

import Foundation

public typealias DLReducer = DevinLaiReducer

public protocol DevinLaiReducer {

  associatedtype ViewModel: DLReducibleViewModel

  typealias Properties = ViewModel.Properties

  associatedtype Action

  static func reduce(_ action: Action, with properties: Properties)

}

extension DevinLaiReducer where ViewModel: DLEventPublisher {

  public static func fireEvent(_ event: ViewModel.Event, with properties: Properties) {
      properties.fireEvent(event)
  }

}

