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
            case .dismiss:
                // Request parent to dismiss by sending dismiss request
                state.fireDismiss()
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
        
        /// Creates an array of scoped child view models from an IdentifiedArray
        ///
        /// This method provides type-safe scoping for identified collections, ensuring
        /// compile-time safety and preventing runtime errors from non-identified collections.
        ///
        /// **Type Safety**: Only works with IdentifiedArray, preventing misuse with plain arrays.
        /// **Performance**: Intelligent caching returns the same array instance when content is unchanged.
        /// **SwiftUI Integration**: Provides stable references for SwiftUI containers like ScrollViewReader.
        ///
        /// - Parameters:
        ///   - arrayKeyPath: The keyPath to the IdentifiedArray of child states
        ///   - toParentAction: Maps child events to parent actions
        ///   - childReducer: The reducer for the child state
        /// - Returns: An array of scoped child view models with intelligent caching
        public func scope<ChildState: BusinessState>(
            identifiedArray arrayKeyPath: KeyPath<State, IdentifiedArray<ChildState>>,
            event toParentAction: ((ChildState.R.Event) -> State.R.Action)? = nil,
            reducer childReducer: ChildState.R
        ) -> [DLViewModel<ChildState>] where ChildState.R.State == ChildState {
            let key = cacheKey(keyPath: arrayKeyPath, reducerType: type(of: childReducer))
            let identifiedArray = state[keyPath: arrayKeyPath]
            
            // Array-level caching key based on state content
            let arrayContentKey = key + "_identified_array"
            
            // Check if we have a cached array with the same content
            if let cachedContainer = object(forKey: arrayContentKey) as? CachedViewModelArray<ChildState>,
               cachedContainer.hasEqualContent(to: identifiedArray) {
                // Update existing ViewModels with new state if needed
                for (index, childState) in identifiedArray.enumerated() {
                    if index < cachedContainer.viewModels.count {
                        let cachedViewModel = cachedContainer.viewModels[index]
                        if cachedViewModel.updateState(childState) {
                            subscribeIfNeeded(
                                state: childState,
                                childViewModel: cachedViewModel,
                                event: toParentAction,
                                reducer: childReducer
                            )
                        }
                    }
                }
                // Return the same array instance for SwiftUI stability
                return cachedContainer.viewModels
            }
            
            // Content changed or no cache - rebuild array
            let cachedViewModels = object(forKey: key) as? ArrayViewModels ?? ArrayViewModels()
            let newCachedViewModels = ArrayViewModels()
            let viewModels = identifiedArray.map { childState in
                let childKey = String(describing: childState.id)

                if let cachedViewModel = cachedViewModels.object(forKey: childKey) as? DLViewModel<ChildState> {
                    if cachedViewModel.updateState(childState) {
                        subscribeIfNeeded(
                            state: childState,
                            childViewModel: cachedViewModel,
                            event: toParentAction,
                            reducer: childReducer
                        )
                    }
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

            // Cache both individual ViewModels and the array container
            setObject(newCachedViewModels, forKey: key)
            let container = CachedViewModelArray(viewModels: viewModels, contentSnapshot: identifiedArray)
            setObject(container, forKey: arrayContentKey)
            
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

            childViewModel.state.requestPublisher
                .print("↖️ [Request]: \(from) -> \(to)")
                .sink { [weak self, childViewModel] request in
                    guard let self else { return }
                    switch request {
                    case .dismiss:
                        guard let navigatableParent = self.state as? any NavigatableState else { return }
                        navigatableParent.dismissAny()

                    case let .event(childEvent):
                        // Handle business event
                        if let parentAction = toParentAction?(childEvent) {
                            self.send(parentAction)
                        }

                    case let .command(childCommand):
                        let effect = childViewModel.reducer.reduce(into: childViewModel.state, command: childCommand)
                        childViewModel.executeEffect(effect)
                    }
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
