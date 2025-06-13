//
//  DLViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Combine
import Foundation

public typealias DLViewModel = DLVVM.DLViewModel
public typealias ViewModelOf<R: Reducer> = DLViewModel<R.State>

// MARK: - DLVVM.DLViewModel

public extension DLVVM {
    @MainActor
    @dynamicMemberLookup
    @Observable
    final class DLViewModel<State: DLVVM.BusinessState> {
        public var state: State
        private let reducer: State.R
        private var effectTasks: [UUID: AnyCancellable] = [:]
        private var subscription = Set<AnyCancellable>()

        public init(
            initialState: State,
            _ reducer: () -> State.R
        ) {
            self.state = initialState
            self.reducer = reducer()
        }

        public subscript<Value>(dynamicMember keyPath: WritableKeyPath<State, Value>) -> Value {
            get { state[keyPath: keyPath] }
            set { state[keyPath: keyPath] = newValue }
        }

        public subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
            state[keyPath: keyPath]
        }

        public func send(_ action: State.R.Action) {
            let effect = reducer.reduce(into: state, action: action)
            executeEffect(effect)
        }

        private func executeEffect(_ effect: DLVVM.Effect<State.R.Action>) {
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

        // 產生快取 key
        private func cacheKey<ChildState>(
            keyPath: WritableKeyPath<State, ChildState>,
            reducerType: Any.Type
        ) -> String {
            let keyPathString = String(describing: keyPath)
            let reducerString = String(describing: reducerType)
            return "\(keyPathString)_\(reducerString)"
        }

        // 使用 NSMapTable 來存儲弱引用的子 ViewModel
        private var childViewModels = NSMapTable<NSString, AnyObject>.strongToWeakObjects()

        public func scope<ChildState: BusinessState>(
            state keyPath: WritableKeyPath<State, ChildState>,
            event toParentEvent: @escaping (ChildState.R.Event) -> State.R.Action,
            reducer childReducer: ChildState.R
        ) -> DLViewModel<ChildState> where ChildState.R.State == ChildState {
            let key = cacheKey(keyPath: keyPath, reducerType: type(of: childReducer))
            if let cachedViewModel = childViewModels.object(forKey: key as NSString) as? DLViewModel<ChildState> {
                return cachedViewModel
            }

            let childViewModel = DLViewModel<ChildState>(initialState: state[keyPath: keyPath]) {
                childReducer
            }

            childViewModel.eventPublisher
                .print("@@@@")
                .sink { [weak self] childEvent in
                    let parentAction = toParentEvent(childEvent)
                    self?.send(parentAction)
                }
                .store(in: &subscription)
            // 儲存到快取
            childViewModels.setObject(childViewModel, forKey: key as NSString)

            return childViewModel
        }
    }
}
