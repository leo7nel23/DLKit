//
//  DLVVM+NavigationTypes.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/7/18.
//

import Foundation

public extension DLVVM {
    enum RouteStyle: Equatable {
        case push
        case fullScreenCover
        case sheet
    }
    
    enum DismissType {
        case dismiss
        case pop
        case popToRoot
        case dismissSheet
        case dismissFullCover
    }
}

public typealias RouteStyle = DLVVM.RouteStyle
public typealias DismissType = DLVVM.DismissType

struct AnyNextStateKeyPath<State: NavigatableState, NextState: BusinessState> {

    let keyPath: WritableKeyPath<State, NextState?>
    let eventMapper: (NextState.R.Event) -> State.R.Action?
    let reducer: NextState.R
    let routeStyle: RouteStyle

    init(
        keyPath: WritableKeyPath<State, NextState?>,
        eventMapper: @escaping (NextState.R.Event) -> State.R.Action?,
        reducer: NextState.R,
        routeStyle: RouteStyle
    ) {
        self.keyPath = keyPath
        self.eventMapper = eventMapper
        self.reducer = reducer
        self.routeStyle = routeStyle
    }

    func eraseToNextKeyPath() -> TypeErasedNextStateKeyPath<State> {
        .init(self)
    }
}

struct NavigationStateKeyPath<State: NavigatableState, NextState: NavigationFlow, RootState: NavigatableState> {

    let keyPath: WritableKeyPath<State, NextState?>
    let eventMapper: (NextState.R.Event) -> State.R.Action?
    let rootState: RootState
    let rootReducer: RootState.R
    let routeStyle: RouteStyle

    init(
        keyPath: WritableKeyPath<State, NextState?>,
        eventMapper: @escaping (NextState.R.Event) -> State.R.Action?,
        rootState: RootState,
        rootReducer: RootState.R,
        routeStyle: RouteStyle
    ) {
        self.keyPath = keyPath
        self.eventMapper = eventMapper
        self.rootState = rootState
        self.rootReducer = rootReducer
        self.routeStyle = routeStyle
    }

    func eraseToNextKeyPath() -> TypeErasedNextStateKeyPath<State> {
        .init(self)
    }
}

/// Type-erased wrapper for navigation state transitions
/// 
/// This struct enables storing different types of navigation keypaths in a uniform way,
/// allowing for flexible navigation routing while maintaining type safety through
/// runtime type checking.
struct TypeErasedNextStateKeyPath<State: BusinessState> {
    // Store original data
    private let _keyPath: Any
    private let _eventMapper: Any
    private let _reducer: Any
    private let routeStyle: RouteStyle

    private let rootState: Any?
    private let rootReducer: Any?

    // Constructor functions
    init<NextState: BusinessState>(
        _ original: AnyNextStateKeyPath<State, NextState>
    ) {
        self._keyPath = original.keyPath
        self._eventMapper = original.eventMapper
        self._reducer = original.reducer
        self.routeStyle = original.routeStyle

        self.rootState = nil
        self.rootReducer = nil
    }

    init<
        NextState: NavigationFlow,
        RootState: NavigatableState
    >(
        _ original: NavigationStateKeyPath<State, NextState, RootState>
    ) {
        self._keyPath = original.keyPath
        self._eventMapper = original.eventMapper
        self._reducer = NavigationFeature()
        self.routeStyle = original.routeStyle
        self.rootState = original.rootState
        self.rootReducer = original.rootReducer
    }

    // Convert back to concrete type
    /// Attempts to convert the type-erased keypath back to a concrete type
    /// 
    /// - Parameter nextType: The expected next state type
    /// - Returns: A concrete keypath if the types match, nil otherwise
    func typed<NextState: BusinessState>(
        as nextType: NextState.Type
    ) -> AnyNextStateKeyPath<State, NextState>? {
        guard let keyPath = _keyPath as? WritableKeyPath<State, NextState?>,
              let eventMapper = _eventMapper as? (NextState.R.Event) -> State.R.Action?,
              let reducer = _reducer as? NextState.R else {
            return nil
        }

        return AnyNextStateKeyPath(
            keyPath: keyPath,
            eventMapper: eventMapper,
            reducer: reducer,
            routeStyle: routeStyle
        )
    }

    /// Attempts to convert to a navigation state keypath
    /// 
    /// - Parameter rootType: The expected root state type
    /// - Returns: A navigation state keypath if the types match, nil otherwise
    func navigationTyped<RootState: NavigatableState>(
        as rootType: RootState.Type
    ) -> NavigationStateKeyPath<State, NavigationFlow, RootState>? {
        guard let keyPath = _keyPath as? WritableKeyPath<State, NavigationFlow?>,
//              let eventMapper = _eventMapper as? (RootState.R.Event) -> State.R.Action?,
              let rootState = rootState as? RootState,
              let rootReducer = rootReducer as? RootState.R else {
            return nil
        }

        return NavigationStateKeyPath(
            keyPath: keyPath,
            eventMapper: { _ in nil },
            rootState: rootState,
            rootReducer: rootReducer,
            routeStyle: routeStyle
        )
    }
}

struct NextStateMatcher<State: NavigatableState> {
    let type: any BusinessState.Type
    let match: (TypeErasedNextStateKeyPath<State>) -> Any?
}