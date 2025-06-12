//
//  DLViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Foundation
import Combine

public typealias DLViewModel = DLVVM.DLViewModel

public extension DLVVM {
    @MainActor
    @dynamicMemberLookup
    protocol DLViewModel: AnyObject {
        associatedtype State: BusinessState
        associatedtype Action
        associatedtype Reducer: BusinessReducer where Reducer.State == State, Reducer.Action == Action

        var state: State { get set }

        init(initialState: State)

        var subscriptions: Set<AnyCancellable> { get set }

        subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value { get }
    }
}

public extension DLVVM.DLViewModel {
    func send(_ action: Action) {
        Reducer.reduce(into: &state, action: action)
    }
    
    subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        state[keyPath: keyPath]
    }
}

public extension DLVVM.DLViewModel {
    func scope<Child: DLViewModel & EventPublisher>(
        state: WritableKeyPath<State, Child.State>,
        mapEvent: @escaping (Child.Event) -> Action?
    ) -> Child {
        let childVM = Child(initialState: self.state[keyPath: state])
        childVM.eventPublisher
            .sink { [weak self] event in
                guard let self,
                      let action = mapEvent(event)
                else { return }
                self.send(action)
            }
            .store(in: &subscriptions)

        return childVM
    }
}

public extension DLVVM.DLViewModel where Self: EventPublisher, State.ViewModel == Self {
    var eventPublisher: AnyPublisher<Event, Never> {
        state.eventSubject.eraseToAnyPublisher()
    }

    func fireEvent(_ event: Event) { state.fireEvent(event) }
}
