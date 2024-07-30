//
//  
//  DLTagViewViewModel.swift
//  
//
//  Created by 賴柏宏 on 2024/7/26.
//
//

import DLVVM

// MARK: - DLTagViewViewModel

public final class DLTagViewViewModel: DLReducibleViewModel, Identifiable {

  public typealias Reducer = DLTagViewReducer

  public let id: String = { UUID().uuidString }()

  private let eventSubject = PassthroughSubject<Event, Never>()
  public var eventPublisher: AnyPublisher<Event, Never> { eventSubject.eraseToAnyPublisher() }
  
  public lazy var observation: ViewObservation = makeViewObservation()

  public let properties: Properties

  public var subscriptions = Set<AnyCancellable>()

  init(defaultText: String = "") {
    properties = Properties(defaultText: defaultText)
    setUpSubscriptions()
  }

  private func setUpSubscriptions() {
    properties.actionPublisher
      .sink { [weak self, observation, eventSubject] action in
        guard let self = self else { return }
        switch action {
          case let .updateText(text):
            observation.tag = text
          case .updateStateToTag:
            observation.isAbleToEdit = false
            observation.isFocused = false
            eventSubject.send(.newTagAdded)
          case .updateStateToField:
            observation.isAbleToEdit = true
            observation.isFocused = true
          case .needToRemove:
            eventSubject.send(.removeIfNeed)
        }
      }
      .store(in: &subscriptions)
  }
}

// MARK: DLTagViewViewModel.Event

extension DLTagViewViewModel: DLEventPublisher {
  public enum Event {
    case newTagAdded
    case removeIfNeed
  }
}

public extension DLTagViewViewModel {
  enum Manipulation {
    case enableEditing
  }

  func manipulate(_ manipulation: Manipulation) {
    reduce(.manipulation(manipulation))
  }
}

extension DLTagViewViewModel {
  @Observable
  public class ViewObservation {
    var tag: String = ""
    var isAbleToEdit = true
    var isFocused = true

    init(tag: String, isAbleToEdit: Bool = true, isFocused: Bool = true) {
      self.tag = tag
      self.isAbleToEdit = isAbleToEdit
      self.isFocused = isFocused
    }
  }

  private func makeViewObservation() -> ViewObservation {
    ViewObservation(tag: properties.currentText)
  }
}

public extension DLTagViewViewModel {
  enum ViewAction {
    case updateTag(String)
    case deleteTapped
  }

  func handle(_ viewAction: ViewAction) {
    reduce(.viewAction(viewAction))
  }
}
