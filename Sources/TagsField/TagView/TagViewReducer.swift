//
//
//  DLTagViewReducer.swift
//
//
//  Created by 賴柏宏 on 2024/7/26.
//
//

import Combine
import DLVVM
import Foundation

// MARK: - DLTagViewViewModel.Properties

public extension DLTagViewViewModel {
  final class Properties: DLProperties {
    public typealias ViewModel = DLTagViewViewModel

    fileprivate let actionSubject = PassthroughSubject<Action, Never>()
    var actionPublisher: AnyPublisher<Action, Never> { actionSubject.eraseToAnyPublisher() }

    enum Action {
      case updateText(String)
      case updateStateToTag
      case updateStateToField
      case needToRemove
    }

    fileprivate(set) var currentText: String = ""

    init(defaultText: String) {
      currentText = defaultText
    }
  }
}

// MARK: - DLTagViewReducer

public enum DLTagViewReducer: DLReducer {
  public typealias ViewModel = DLTagViewViewModel

  public enum Action {
    case viewAction(ViewModel.ViewAction)
    case manipulation(ViewModel.Manipulation)
  }

  public static func reduce(_ action: Action, with properties: Properties) {
    switch action {
    case let .viewAction(viewAction):
      handle(viewAction: viewAction, with: properties)
    case let .manipulation(manipulation):
      handle(manipulation: manipulation, with: properties)
    }
  }

  private static func handle(viewAction: ViewModel.ViewAction, with properties: Properties) {
    switch viewAction {
    case let .updateTag(text):
      if text.hasSuffix(",") || text.hasSuffix(" ") {
        properties.currentText = String(text.dropLast())
        guard !properties.currentText.isEmpty else { return }
        properties.actionSubject.send(.updateText(properties.currentText))
        properties.actionSubject.send(.updateStateToTag)
      } else {
        properties.currentText = text
      }
    case .deleteTapped:
      guard properties.currentText.isEmpty else { return }
      properties.actionSubject.send(.needToRemove)
    }
  }

  private static func handle(manipulation: ViewModel.Manipulation, with properties: Properties) {
    switch manipulation {
    case .enableEditing:
      properties.actionSubject.send(.updateStateToField)
    }
  }
}