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

    private class ArrayViewModels {
        fileprivate var viewModels: [String: AnyObject] = [:]

        func setObject(_ object: AnyObject?, forKey key: String) {
            viewModels[key] = object
        }

        func object(forKey key: String) -> AnyObject? {
            viewModels[key]
        }
    }

    @MainActor
    @dynamicMemberLookup
    @Observable
    final class DLViewModel<State: DLVVM.BusinessState>: @preconcurrency Identifiable, @preconcurrency Hashable, @preconcurrency DLViewModelProtocol {
        public static func == (lhs: DLVVM.DLViewModel<State>, rhs: DLVVM.DLViewModel<State>) -> Bool {
            rhs.id == lhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        func updateState(_ newState: State) -> Bool {
            let old = "\(Unmanaged<AnyObject>.passUnretained(state).toOpaque())"
            let new = "\(Unmanaged<AnyObject>.passUnretained(newState).toOpaque())"
            if old != new {
                state = newState
                id = UUID().uuidString
                return true
            }
            return false
        }

        public private(set) var id: String = UUID().uuidString
        public internal(set) var state: State
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
            let address = "(" + "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque()))".suffix(5)
            print("🌱 [Init] \(String(describing: type(of: self).State.R))" + address)
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

        // Generate cache key for child view model
        private func cacheKey<ChildState>(
            keyPath: KeyPath<State, ChildState>,
            reducerType: Any.Type
        ) -> String {
            let keyPathString = String(describing: keyPath)
            let reducerString = String(describing: reducerType)
            return "\(keyPathString)_\(reducerString)"
        }

        // Store child ViewModels with weak references to prevent retain cycles
        var childViewModels: [String: AnyObject] = [:]

        /// Creates a scoped child view model from a keyPath on the parent state
        ///
        /// This method creates a child view model that observes changes to a specific property
        /// of the parent state. The child view model can send events back to the parent through
        /// the provided event mapper.
        ///
        /// - Parameters:
        ///   - keyPath: The keyPath to the child state property
        ///   - toParentAction: Maps child events to parent actions
        ///   - childReducer: The reducer for the child state
        /// - Returns: A scoped child view model
        public func scope<ChildState: BusinessState>(
            state keyPath: KeyPath<State, ChildState>,
            event toParentAction: ((ChildState.R.Event) -> State.R.Action?)? = nil,
            reducer childReducer: ChildState.R
        ) -> DLViewModel<ChildState> where ChildState.R.State == ChildState {
            let key = cacheKey(keyPath: keyPath, reducerType: type(of: childReducer))
            let state = state[keyPath: keyPath]
            if let cachedViewModel = object(forKey: key) as? DLViewModel<ChildState> {
                if cachedViewModel.updateState(state) {
                    subscribeIfNeeded(
                        state: state,
                        childViewModel: cachedViewModel,
                        event: toParentAction,
                        reducer: childReducer
                    )
                }
                return cachedViewModel
            }

            return _scope(
                state: state,
                event: toParentAction,
                reducer: childReducer,
                cacheKey: key
            )
        }

        /// Creates a scoped child view model from a keyPath on the parent state
        ///
        /// This method creates a child view model that observes changes to a specific property
        /// of the parent state. The child view model can send events back to the parent through
        /// the provided event mapper.
        ///
        /// - Parameters:
        ///   - state: child state property
        ///   - toParentAction: Maps child events to parent actions
        ///   - childReducer: The reducer for the child state
        /// - Returns: A scoped child view model
        public func scope<ChildState: BusinessState>(
            state childState: ChildState,
            event toParentAction: ((ChildState.R.Event) -> State.R.Action)? = nil,
            reducer childReducer: ChildState.R
        ) -> DLViewModel<ChildState> where ChildState.R.State == ChildState {
            let key = "\(Unmanaged<AnyObject>.passUnretained(childState).toOpaque())"
            if let cached = object(forKey: key) as? DLViewModel<ChildState> {
                return cached
            }
            return _scope(
                state: childState,
                event: toParentAction,
                reducer: childReducer,
                cacheKey: key
            )
        }
        
        /// Creates an array of scoped child view models from a keyPath pointing to an array of child states
        ///
        /// This method is useful when the parent state contains an array of child states, and you need
        /// to create individual view models for each child state. Each child view model will be properly
        /// scoped and can send events back to the parent.
        ///
        /// **Requirements**: Child states must conform to Identifiable for optimal performance,
        /// proper caching, and seamless integration with SwiftUI's diffing system.
        ///
        /// - Parameters:
        ///   - arrayKeyPath: The keyPath to the array of Identifiable child states on the parent state
        ///   - toParentAction: Maps child events to parent actions
        ///   - childReducer: The reducer for the child state
        /// - Returns: An array of scoped child view models with intelligent caching
        public func scope<ChildState: BusinessState>(
            stateArray arrayKeyPath: KeyPath<State, [ChildState]>,
            event toParentAction: ((ChildState.R.Event) -> State.R.Action)? = nil,
            reducer childReducer: ChildState.R
        ) -> [DLViewModel<ChildState>] where ChildState.R.State == ChildState, ChildState: Identifiable {
            let key = cacheKey(keyPath: arrayKeyPath, reducerType: type(of: childReducer))
            let childStates = state[keyPath: arrayKeyPath]
            let cachedViewModels = object(forKey: key) as? ArrayViewModels ?? ArrayViewModels()
            setObject(nil, forKey: key)

            let newCachedViewModels = ArrayViewModels()
            let viewModels = childStates.map { childState in
                let childKey = String(describing: childState.id)

                if let cachedViewModel = cachedViewModels.object(forKey: childKey) as? DLViewModel<ChildState> {
                    newCachedViewModels.setObject(cachedViewModel, forKey: childKey)
                    return cachedViewModel
                }

                // Create new view model
                let childViewModel = _scope(
                    state: childState,
                    event: toParentAction,
                    reducer: childReducer,
                    cacheKey: nil
                )

                newCachedViewModels.setObject(childViewModel, forKey: childKey)

                return childViewModel
            }

            setObject(newCachedViewModels, forKey: key)
            return viewModels
        }

        /// Internal method to create a scoped child view model
        /// 
        /// This is the core implementation that handles child view model creation,
        /// event binding, and caching.
        /// 
        /// - Parameters:
        ///   - state: The child state instance
        ///   - toParentAction: Optional event mapper to parent actions
        ///   - childReducer: The reducer for the child state
        ///   - cacheKey: Unique key for caching the child view model
        /// - Returns: A new or cached child view model
        internal func _scope<ChildState: BusinessState>(
            state: ChildState,
            event toParentAction: ((ChildState.R.Event) -> State.R.Action?)?,
            reducer childReducer: ChildState.R,
            cacheKey: String? = nil
        ) -> DLViewModel<ChildState> where ChildState.R.State == ChildState {

            let childViewModel = DLViewModel<ChildState>(
                initialState: state,
                reducer: childReducer
            )

            subscribeIfNeeded(
                state: state,
                childViewModel: childViewModel,
                event: toParentAction,
                reducer: childReducer
            )

            // Store in cache
            setObject(childViewModel, forKey: cacheKey)

            return childViewModel
        }

        private func subscribeIfNeeded<ChildState: BusinessState>(
            state: ChildState,
            childViewModel: DLViewModel<ChildState>,
            event toParentAction: ((ChildState.R.Event) -> State.R.Action?)?,
            reducer childReducer: ChildState.R
        ) {
            guard type(of: state).R.Event != Void.self else { return }
            let fromAddress = "(" + "\(Unmanaged<AnyObject>.passUnretained(childViewModel).toOpaque())".suffix(5) + ")"
            let from = String(describing: ChildState.self.R) + fromAddress
            let toAddress = "(" + "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque())".suffix(5) + ")"
            let to = String(describing: type(of: self.state).R) + toAddress

            childViewModel.eventPublisher
                .print("↖️ [Event]: \(from) -> \(to)")
                .compactMap { toParentAction?($0) }
                .sink { [weak self] parentAction in
                    self?.send(parentAction)
                }
                .store(in: &subscription)
        }

        internal func setObject(_ object: AnyObject?, forKey defaultName: String?) {
            guard let defaultName else { return }
            childViewModels[defaultName] = object

            let address = "(" + "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque()))".suffix(5)
            let from = String(describing: Self.State.R)
            print("[\(from) - \(address)] count = \(childViewModels.count)")
        }

        internal func object(forKey key: String) -> AnyObject? {
            childViewModels[key]
        }

        deinit {
            let address = "(" + "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque()))".suffix(5)
            print("♻️ [Deinit] \(String(describing: type(of: self).State.R))" + address)
        }
    }
}
