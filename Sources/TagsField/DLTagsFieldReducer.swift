//
//
//  DLTagsFieldReducer.swift
//
//
//  Created by 賴柏宏 on 2024/7/26.
//
//

import Combine
import DLVVM
import Foundation

// MARK: - DLTagsFieldViewModel.Properties

public extension DLTagsFieldViewModel {
  final class Properties: DLProperties {
    public typealias ViewModel = DLTagsFieldViewModel
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

// MARK: - DLTagsFieldReducer

public enum DLTagsFieldReducer: DLReducer {
  public typealias ViewModel = DLTagsFieldViewModel

  public enum Action {
    case viewAction(ViewModel.ViewAction)
    case manipulation(ViewModel.Manipulation)
    case tagEventReceived(DLTagViewViewModel.Event)
  }

  public static func reduce(_ action: Action, with properties: Properties) {
    switch action {
    case let .viewAction(viewAction):
      handle(viewAction: viewAction, with: properties)
    case let .manipulation(manipulation):
      handle(manipulation: manipulation, with: properties)
    case let .tagEventReceived(event):
        handle(event, with: properties)
    }
  }

  private static func handle(viewAction: ViewModel.ViewAction, with _: Properties) {
    switch viewAction {}
  }

  private static func handle(manipulation: ViewModel.Manipulation, with _: Properties) {
    switch manipulation {}
  }

  private static func handle(_ event: DLTagViewViewModel.Event, with properties: Properties) {
    switch event {
      case .removeIfNeed:
        properties.actionSubject.send(.popFieldIfNeed)
      case .newTagAdded:
        properties.actionSubject.send(.insertEmptyField)
    }
  }
}
