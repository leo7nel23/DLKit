//
//  DLViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Combine
import Foundation

public typealias DLViewModel = DLVVM.DLViewModel

// MARK: - DLVVM.DLViewModel

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

        subscript<Value>(dynamicMember _: KeyPath<State, Value>) -> Value { get }
    }
}

public extension DLVVM.DLViewModel {
    func send(_ action: Action) {
        let effect = Reducer.reduce(into: &state, action: action)
        executeEffect(effect)
    }

    subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        state[keyPath: keyPath]
    }

    private func executeEffect(_ effect: DLVVM.Effect<Action>) {
        let uuid = UUID()
        switch effect.operation {
        case .none:
            break

        case let .run(priority, operation):
            let task = Task(priority: priority) { @MainActor [weak self] in
                await operation(
                    Send { effectAction in
                        self?.send(effectAction)
                    }
                )
                self?.effectTasks[uuid] = nil
            }
            effectTasks[uuid] = AnyCancellable { @Sendable in
                task.cancel()
            }
        }
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

private nonisolated(unsafe) var effectTasksAssociatedKey: Void?

extension DLVVM.DLViewModel {
    var effectTasks: [UUID: AnyCancellable] {
        get {
            if let subject = objc_getAssociatedObject(
                self,
                &effectTasksAssociatedKey
            ) as? [UUID: AnyCancellable] {
                return subject
            } else {
                let effectTasks = [UUID: AnyCancellable]()
                objc_setAssociatedObject(
                    self,
                    &effectTasksAssociatedKey,
                    effectTasks,
                    .OBJC_ASSOCIATION_RETAIN
                )
                return effectTasks
            }
        }
        set {
            objc_setAssociatedObject(
                self,
                &effectTasksAssociatedKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
    }
}

public extension DLVVM.DLViewModel where Self: EventPublisher, State.ViewModel == Self {
    var eventPublisher: AnyPublisher<Event, Never> {
        state.eventSubject.eraseToAnyPublisher()
    }

    func fireEvent(_ event: Event) { state.fireEvent(event) }
}
