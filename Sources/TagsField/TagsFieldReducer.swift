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
      case popField
    }

    let placeholder: String?
    @Published fileprivate(set) var currentTags: [String]

    init(placeholder: String?, defaultTags: [String]) {
      self.placeholder = placeholder
      currentTags = defaultTags
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
        guard !properties.currentTags.isEmpty else { return }
        properties.currentTags.removeLast()
        properties.actionSubject.send(.popField)
      case let .newTagAdded(tag):
        properties.currentTags.append(tag)
        properties.actionSubject.send(.insertEmptyField)
    }
  }
}
