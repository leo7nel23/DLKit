//
//
//  TagsFieldReducer.swift
//
//
//  Created by 賴柏宏 on 2024/7/26.
//
//

import Combine
import DLVVM
import Foundation

// MARK: - TagsFieldViewModel.Properties

public extension TagsFieldViewModel {
  final class Properties: DLProperties {
    public typealias ViewModel = TagsFieldViewModel
    fileprivate let actionSubject = PassthroughSubject<Action, Never>()
    var actionPublisher: AnyPublisher<Action, Never> { actionSubject.eraseToAnyPublisher() }

    enum Action {
      case insertEmptyField
      case popFieldIfNeed
    }

    init() {
    }
  }
}

// MARK: - TagsFieldReducer

public enum TagsFieldReducer: DLReducer {
  public typealias ViewModel = TagsFieldViewModel

  public enum Action {
    case tagEventReceived(TagViewViewModel.Event)
  }

  public static func reduce(_ action: Action, with properties: Properties) {
    switch action {
    case let .tagEventReceived(event):
        handle(event, with: properties)
    }
  }

  private static func handle(_ event: TagViewViewModel.Event, with properties: Properties) {
    switch event {
      case .removeIfNeed:
        properties.actionSubject.send(.popFieldIfNeed)
      case .newTagAdded:
        properties.actionSubject.send(.insertEmptyField)
    }
  }
}
