//
//  DLViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Combine
import Foundation

public typealias DLViewModel = DLVVM.DLViewModel
public typealias DLViewModelProtocol = DLVVM.DLViewModelProtocol
public typealias ViewModelOf<R: Reducer> = DLViewModel<R.State>

// MARK: - DLVVM.DLViewModel

public extension DLVVM {
    protocol DLViewModelProtocol: Identifiable, AnyObject {
        associatedtype State: BusinessState
        var id: String { get }
        var state: State { get }
        var reducer: State.R { get }
    }

    @MainActor
    @dynamicMemberLookup
    @Observable
    final class DLViewModel<State: DLVVM.BusinessState>: Identifiable,  @preconcurrency DLViewModelProtocol {
        public let id: String = UUID().uuidString
        public var state: State
        public let reducer: State.R
        private var effectTasks: [UUID: AnyCancellable] = [:]
        var subscription = Set<AnyCancellable>()

        internal var navigatableKeyPaths: [String: () -> Void] = [:]

        public init(
            initialState: State,
            reducer: State.R
        ) {
            self.state = initialState
            self.reducer = reducer
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

        private func executeEffect(_ effect: DLVVM.Procedure<State.R.Action, State>) {
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
        var childViewModels: [String: AnyObject] = [:]

        public func scope<ChildState: BusinessState>(
            state keyPath: WritableKeyPath<State, ChildState>,
            event toParentAction: @escaping (ChildState.R.Event) -> State.R.Action?,
            reducer childReducer: ChildState.R
        ) -> DLViewModel<ChildState> where ChildState.R.State == ChildState {
            let key = cacheKey(keyPath: keyPath, reducerType: type(of: childReducer))
            if let cachedViewModel = childViewModels[key] as? DLViewModel<ChildState> {
                return cachedViewModel
            }

            let state = state[keyPath: keyPath]
            return _scope(
                state: state,
                event: toParentAction,
                reducer: childReducer,
                cacheKey: key
            )
        }

        internal func _scope<ChildState: BusinessState>(
            state: ChildState,
            event toParentAction: @escaping (ChildState.R.Event) -> State.R.Action?,
            reducer childReducer: ChildState.R,
            cacheKey: String
        ) -> DLViewModel<ChildState> where ChildState.R.State == ChildState {

            let childViewModel = DLViewModel<ChildState>(
                initialState: state,
                reducer: childReducer
            )

            let fromAddress = "(\(Unmanaged<AnyObject>.passUnretained(state).toOpaque()))"
            let from = String(describing: ChildState.self.R) + fromAddress
            let toAddress = "(\(Unmanaged<AnyObject>.passUnretained(self.state).toOpaque()))"
            let to = String(describing: type(of: self.state).R) + toAddress

            childViewModel.eventPublisher
                .print("↖️ [Event]: \(from) -> \(to)")
                .compactMap { toParentAction($0) }
                .sink { [weak self] parentAction in
                    self?.send(parentAction)
                }
                .store(in: &subscription)
            // 儲存到快取
            childViewModels[cacheKey] = childViewModel

            return childViewModel
        }

        deinit {
            let address = "(\(Unmanaged<AnyObject>.passUnretained(self).toOpaque()))"
            print("♻️ [Deinit] \(String(describing: type(of: self).State.R))" + address)
        }
    }
}
