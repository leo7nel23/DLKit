//
//  
//  TagsFieldViewModel.swift
//  
//
//  Created by 賴柏宏 on 2024/7/26.
//
//

import DLVVM

// MARK: - TagsFieldViewModel

public final class TagsFieldViewModel: DLReducibleViewModel {

  public typealias Reducer = TagsFieldReducer

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

// MARK: TagsFieldViewModel.Event

extension TagsFieldViewModel: DLEventPublisher {
  public enum Event {

  }
}

extension TagsFieldViewModel {
  @Observable
  public class ViewObservation {
    fileprivate(set) var tagViewModels: [TagViewViewModel]

    init(tagViewModels: [TagViewViewModel]) {
      self.tagViewModels = tagViewModels
    }
  }

  private func makeViewObservation() -> ViewObservation {
    ViewObservation(tagViewModels: [
      makeTagViewModel()
    ])
  }

  private func makeTagViewModel(_ text: String? = nil) -> TagViewViewModel {
    makeSubViewModel {
      TagViewViewModel()
    } convertAction: { .tagEventReceived($0) }
  }
}
