//
//  
//  DLTagsFieldViewModel.swift
//  
//
//  Created by 賴柏宏 on 2024/7/26.
//
//

import DLVVM

// MARK: - DLTagsFieldViewModel

public final class DLTagsFieldViewModel: DLReducibleViewModel {

  public typealias Reducer = DLTagsFieldReducer

  private let eventSubject = PassthroughSubject<Event, Never>()
  public var eventPublisher: AnyPublisher<Event, Never> { eventSubject.eraseToAnyPublisher() }
  
  public lazy var observation: ViewObservation = makeViewObservation()

  public let properties: Properties

  public var subscriptions = Set<AnyCancellable>()

  public init() {
    properties = Properties()
    setUpSubscriptions()
  }

  private func setUpSubscriptions() {
    properties.actionPublisher
      .sink { [weak self, observation] action in
        guard let self = self else { return }
        switch action {
          case .insertEmptyField:
            observation.tagViewModels.append(makeTagViewModel())
          case .popFieldIfNeed:
            guard observation.tagViewModels.count > 1 else { return }
            observation.tagViewModels.removeLast()
            observation.tagViewModels.last?.manipulate(.enableEditing)
        }
      }
      .store(in: &subscriptions)
  }
}

// MARK: DLTagsFieldViewModel.Event

extension DLTagsFieldViewModel: DLEventPublisher {
  public enum Event {

  }
}

public extension DLTagsFieldViewModel {
  enum Manipulation {

  }

  func manipulate(_ manipulation: Manipulation) {
    reduce(.manipulation(manipulation))
  }
}

extension DLTagsFieldViewModel {
  @Observable
  public class ViewObservation {
    fileprivate(set) var tagViewModels: [DLTagViewViewModel]

    init(tagViewModels: [DLTagViewViewModel]) {
      self.tagViewModels = tagViewModels
    }

  }

  private func makeViewObservation() -> ViewObservation {
    ViewObservation(tagViewModels: [
      makeTagViewModel()
    ])
  }

  private func makeTagViewModel(_ text: String? = nil) -> DLTagViewViewModel {
    makeSubViewModel {
      DLTagViewViewModel()
    } convertAction: { .tagEventReceived($0) }
  }
}

public extension DLTagsFieldViewModel {
  enum ViewAction {}

  func handle(_ viewAction: ViewAction) {
    reduce(.viewAction(viewAction))
  }
}
