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

  public init(placeholder: String?, defaultTags: [String] = []) {
    properties = Properties(placeholder: placeholder, defaultTags: defaultTags)
    setUpSubscriptions()
  }

  private func setUpSubscriptions() {
    properties.actionPublisher
      .sink { [weak self, observation] action in
        guard let self = self else { return }
        switch action {
          case .insertEmptyField:
            observation.tagViewModels.append(makeTagViewModel())

          case .popField:
            observation.tagViewModels.removeLast()
            observation.tagViewModels.last?.manipulate(.enableEditing)
        }
      }
      .store(in: &subscriptions)

    properties.$currentTags
      .sink { [eventSubject] in
        eventSubject.send(.tagsUpdated($0))
      }
      .store(in: &subscriptions)
  }
}

// MARK: TagsFieldViewModel.Event

extension TagsFieldViewModel: DLEventPublisher {
  public enum Event {
    case tagsUpdated([String])
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
    let tagModels = properties.currentTags.map { makeTagViewModel($0) }
    return ViewObservation(tagViewModels: tagModels + [makeTagViewModel()])
  }

  private func makeTagViewModel(_ text: String? = nil) -> TagViewViewModel {
    makeSubViewModel {
      TagViewViewModel(placeholder: properties.placeholder, tag: text)
    } convertAction: { .tagEventReceived($0) }
  }
}
